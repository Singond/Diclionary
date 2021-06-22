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
		nodeset.each do |node|
			sense.text += node.content
		end
		entry.senses << sense
		entry
	end
end
