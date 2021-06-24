require "http/client"
require "xml"

class SsjcDictionary
	def search(word : String) : Entry
		params = {"heslo" => word, "hsubstr" => "no", "where" => "hesla"}
		url = "https://ssjc.ujc.cas.cz/search.php?" + HTTP::Params.encode(params)
		r = HTTP::Client.get(url)
		html = XML.parse_html(r.body)
		e = html.xpath("/html/body/div[1]/p[@class='entryhead']/*")
		case e
		in Bool, Float64, String
			abort "Unexpected result #{e}", 2
		in XML::NodeSet
			return parse_entry(e)
		end
	end

	def parse_entry(nodeset : XML::NodeSet) : Entry
		entry = Entry.new ""
		sense = Sense.new
		expect_headword = true
		first_sense = true
		nodeset.each do |node|
			cls = (node["class"]? || "").split
			if (expect_headword && cls.includes?("hw") && cls.includes?("bo"))
				entry.headword = node.content
				expect_headword = false
			elsif (cls.includes?("delim") && node.content != "♦ ")
				if (first_sense)
					# Sense already instantiated
					first_sense = false
				else
					# Start a new sense
					entry.senses << sense
					sense = Sense.new
				end
			else
				sense.text += node.content
			end
		end
		entry.senses << sense
		entry
	end
end
