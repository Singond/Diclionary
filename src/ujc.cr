require "./core.cr"

# Helper module to interact with the online dictionaries provided
# by the Czech Language Institute (UJC).
module Diclionary::Ujc

	abstract struct UjcDictionary < Dictionary

		# Parses node set as a dictionary entry.
		#
		# This helper method delegates to one of the methods
		# `#parse_entry_plain`, `#parse_entry_rich` or `#parse_entry_structured`
		# based on the given *format*.
		# Of these methods, only the first two must be implemented.
		# If `#parse_entry_structured` is missing, it defaults to
		# `#parse_entry_rich`.
		def parse_entry(nodeset : XML::NodeSet, format : Format) : Array(Entry)
			entries = Array(Entry).new(1)
			unless nodeset.empty?
				case format
				in Format::PlainText
					entry = parse_entry_plain(nodeset)
				in Format::RichText
					entry = parse_entry_rich(nodeset)
				in Format::Structured
					if responds_to?(:parse_entry_structured)
						entry = self.parse_entry_structured(nodeset)
					else
						entry = parse_entry_rich(nodeset)
					end
				end
				entries << entry
			end
			entries
		end

		def parse_entry_plain(nodeset : XML::NodeSet) : TextEntry
			Log.debug {"Parsing #{nodeset.size} XML nodes as text entry"}
			entry_text = ""
			nodeset.each do |node|
				cls = (node["class"]? || "").split
				text = node.content
				if cls.includes?("delim") && /\s*[0-9]+\./ =~ node.content
					text = "\n" + text
				end
				entry_text += text
			end
			TextEntry.new markup(entry_text)
		end
	end
end
