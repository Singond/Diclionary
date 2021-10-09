require "http/client"
require "uri"
require "xml"

require "./core.cr"

include Diclionary::Text

module Diclionary::Ujc
	SSJC = SsjcDictionary.new("ssjc", "Slovník spisovného jazyka českého")

	struct SsjcDictionary < Dictionary
		URL = URI.new("https", "ssjc.ujc.cas.cz")

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
			# parent = markup()
			parents = Deque(Markup).new
			parents.push(markup())
			nodeset.each do |node|
				cls = (node["class"]? || "").split
				if cls.includes?("delim") && /\s*[0-9]+\./ =~ node.content
					if node.content.strip.starts_with? "1"
						list = OrderedList.new [] of Markup
						parents.last.children << list
						parents.push list
					end
					until parents.last.is_a? OrderedList
						parents.pop
					end
					item = Item.new([] of Markup)
					parents.last.children << item
					parents.push item
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
