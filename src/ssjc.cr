require "http/client"
require "uri"
require "xml"

module Diclionary
	class SsjcDictionary
		URL = URI.new("https", "ssjc.ujc.cas.cz")

		def search(word : String, format : Format) : Array(Entry)
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

		private def parse_response(html, format : Format) : Array(Entry)
			e = html.xpath("/html/body/div[1]/p[@class='entryhead']/*")
			case e
			in Bool, Float64, String
				abort "Unexpected result #{e}", 2
			in XML::NodeSet
				if e.empty?
					return [] of Entry
				end
				case format
					in Format::Text
						return [parse_entry_plain(e)] of Entry
					in Format::Structured
						return [parse_entry_structured(e)] of Entry
				end
			end
		end

		def parse_entry_plain(nodeset : XML::NodeSet) : TextEntry
			Log.debug {"Parsing #{nodeset.size} XML nodes as text entry"}
			entry = TextEntry.new
			nodeset.each do |node|
				cls = (node["class"]? || "").split
				text = node.content
				fmt = FormattedString::Format.new
				if cls.includes?("delim") && /\s*[0-9]+\./ =~ node.content
					text = "\n" + text
				end
				if cls.includes?("it")
					fmt.bold = true
				end
				if cls.includes?("np")
					fmt.dim = true
				end
				entry.text << FormattedString.new(text, fmt)
			end
			entry
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
