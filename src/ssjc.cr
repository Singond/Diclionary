require "http/client"
require "uri"
require "xml"

require "./core.cr"
require "./languages.cr"

include Diclionary::Text

module Diclionary::Ujc
	SSJC = SsjcDictionary::INSTANCE

	struct SsjcDictionary < Dictionary
		INSTANCE = new
		URL = URI.new("https", "ssjc.ujc.cas.cz")
		FIRST_ITEM_REGEX = /([^0-9]*)1.$/

		def initialize(*args)
			super("ssjc", "Slovník spisovného jazyka českého")
			@search_languages = [Language::Czech]
		end

		def search(word : String, format : Format) : SearchResult
			params = {"heslo" => word, "hsubstr" => "no", "where" => "hesla"}
			url = "/search.php?" + HTTP::Params.encode(params)
			Log.info {"Querying '#{URL}#{url}'"}
			t_start = Time.monotonic
			client = HTTP::Client.new(URL)
			r = client.get(url)
			client.close
			t_end = Time.monotonic - t_start
			Log.info {"Got response in #{t_end.total_seconds.round(3)} s."}
			Log.debug {"Parsing response"}
			parse_response(XML.parse_html(r.body), format)
		end

		private def parse_response(html, format : Format) : SearchResult
			e = html.xpath("/html/body/div[1]/p[@class='entryhead']/*")
			case e
			in Bool, Float64, String
				abort "Unexpected result #{e}", 2
			in XML::NodeSet
				if e.empty?
					entries = [] of Entry
				else
					case format
					in Format::PlainText
						entry = parse_entry_plain(e)
					in Format::RichText
						entry = parse_entry_rich(e)
					in Format::Structured
						entry = parse_entry_structured(e)
					end
					entries = [entry] of Entry
				end
			end
			SearchResult.new(entries)
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

		def parse_entry_rich(nodeset : XML::NodeSet) : TextEntry
			Log.debug {"Parsing #{nodeset.size} XML nodes as rich text entry"}
			parents = Deque(Markup).new
			par = Paragraph.new [] of Markup
			root = markup(par)
			parents.push(root)
			parents.push(par)
			node = nodeset[0]
			loop do
				cls = (node["class"]? || "").split
				if cls.includes?("delim") && /\s*[0-9]+\./ =~ node.content
					item_prefix: String?
					# If the delimiter looks like a first item, start a new list.
					if match = node.content.strip.match FIRST_ITEM_REGEX
						# If the item has a non-numeric prefix,
						# store it away for later insertion
						# (there is no way to put it directly
						# into the item marker).
						prefix = match[1]?
						if prefix && !prefix.empty?
							item_prefix = prefix
						end
						list = OrderedList.new [] of Markup
						parents.last.children << list
						parents.push list
					end
					# Return to the innermost list (if any)
					# and start next item underneath.
					if parents.any? {|e| e.is_a? OrderedList}
						until parents.last.is_a? OrderedList
							parents.pop
						end
						item = Item.new([] of Markup)
						if item_prefix
							# Insert the item prefix here
							item.children << bold(item_prefix)
							item.children << markup(" ")
							item_prefix = nil
						end
						parents.last.children << item
						parents.push item
					end
				elsif (cls.includes?("delim") && cls.includes?("bo") \
							&& node.content =~ /\x{2014}|\x{2192}(.*)/) \
						|| node.content =~ /\x{25CB}(.*)/
						#&& (match = node.content.match SUBHEADWORD_REGEX)
					until parents.last.is_a? Paragraph
						parents.pop
					end
					parents.pop
					par = Paragraph.new([] of Markup)
					suffix = $~[1]?
					if suffix && !suffix.blank?
						par.children << markup(suffix.strip + " ")
					end
					parents.last.children << par
					parents.push par
				else
					elem = markup(node.content)
					if cls.includes?("it")
						elem = bold(elem)
					end
					if cls.includes?("np")
						elem = small(elem)
					end
					parents.last.children << elem
				end
				break unless node = node.next
			end
			TextEntry.new parents.first
		end

		def parse_entry_structured(nodeset : XML::NodeSet) : StructuredEntry
			Log.debug {"Parsing #{nodeset.size} XML nodes as structured entry"}
			entry = StructuredEntry.new ""
			sense = Sense.new
			entry.top_sense = sense
			expect_headword = true
			expect_definition = false
			nodeset.each do |node|
				cls = (node["class"]? || "").split
				if (expect_headword && cls.includes?("hw") && cls.includes?("bo"))
					entry.headword = node.content
					expect_headword = false
					expect_definition = true
				elsif (cls.includes?("delim") && /\s*[0-9]+\./ =~ node.content)
					sense = Sense.new
					entry.senses << sense
					expect_definition = true
				# elsif expect_definition && cls.includes?("it")
				elsif expect_definition
					sense.definition += node.content
					if /.*:\s*/ =~ node.content
						expect_definition = false
					end
				else
					sense.text += node.content
				end
			end
			entry
		end
	end
end
