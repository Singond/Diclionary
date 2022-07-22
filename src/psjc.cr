require "http/client"
require "uri"
require "xml"

require "./core.cr"
require "./languages.cr"
require "./ujc.cr"

include Diclionary::Text

module Diclionary::Ujc
	PSJC = PsjcDictionary::INSTANCE

	struct PsjcDictionary < UjcDictionary
		INSTANCE = new
		URL = URI.new("https", "psjc.ujc.cas.cz")
		FIRST_ITEM_REGEX = /^([^0-9]*)1.$/

		def initialize(*args)
			super("psjc", "Příruční slovník jazyka českého")
			@search_languages = [Language::Czech]
		end

		def search(word : String, format : Format) : Array(SearchResult)
			params = {"heslo" => word, "hsubstr" => "no", "where" => "hesla"}
			url = "/search.php?" + HTTP::Params.encode(params)
			client = HTTP::Client.new(URL)
			r = get_url(client, url)
			Log.debug {"Parsing response"}
			parse_response(XML.parse_html(r.body), format).map do |entry|
				SearchResult.new(entry, dictionary: self, term: word)
			end
		end

		def parse_response(html, format : Format) : Array(Entry)
			ns = html.xpath(
				"/html/body/center/form/table[2]/tr[1]/td[1]/ul/li/node()")
				.as?(XML::NodeSet)
			ns ? parse_entry(ns, format) : [] of Entry
		end

		def parse_entry_rich(nodeset : XML::NodeSet) : TextEntry
			Log.debug {"Parsing #{nodeset.size} XML nodes as rich text entry"}
			# parent = markup()
			parents = Deque(Markup).new
			parents.push(markup())
			nodeset.each do |node|
				cls = (node["class"]? || "").split
				if cls.includes?("delim") && /\s*[0-9]+\./ =~ node.content
					if node.content.strip == "1."
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
					if cls.includes?("i")
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
	end
end
