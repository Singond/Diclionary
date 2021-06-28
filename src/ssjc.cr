require "http/client"
require "xml"

class SsjcDictionary
	@logger = ::Log.for("xxx")
	def search(word : String, format : Format)
		params = {"heslo" => word, "hsubstr" => "no", "where" => "hesla"}
		url = "https://ssjc.ujc.cas.cz/search.php?" + HTTP::Params.encode(params)
		@logger.info {"Querying '#{url}'"}
		r = HTTP::Client.get(url)
		html = XML.parse_html(r.body)
		e = html.xpath("/html/body/div[1]/p[@class='entryhead']/*")
		case e
		in Bool, Float64, String
			abort "Unexpected result #{e}", 2
		in XML::NodeSet
			case format
				in Format::Text
					return parse_entry_plain(e)
				in Format::Structured
					return parse_entry_structured(e)
			end
		end
	end

	def parse_entry_plain(nodeset : XML::NodeSet) : TextEntry
		entry = TextEntry.new
		nodeset.each do |node|
			cls = (node["class"]? || "").split
			text = node.content
			fmt = FormattedText::Format.new
			if cls.includes?("delim") && /\s*[0-9]+\./ =~ node.content
				text = "\n" + text
			end
			if cls.includes?("it")
				fmt.bold = true
			end
			if cls.includes?("np")
				fmt.dim = true
			end
			entry.text << FormattedText.new(text, fmt)
		end
		entry
	end

	def parse_entry_structured(nodeset : XML::NodeSet) : StructuredEntry
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
