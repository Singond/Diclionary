require "../src/languages.cr"
require "./lipsum.cr"

include Diclionary

struct FakeDictionary < Dictionary
	getter entries = Hash(String, Entry).new

	def search_languages=(langs)
		@search_languages = langs
	end

	def search(word, format) : Array(SearchResult)
		if @entries.has_key? word
			[SearchResult.new(@entries[word], dictionary: self, term: word)]
		else
			[] of SearchResult
		end
	end
end

Cs1 = FakeDictionary.new("zsjc", "Zkušební slovník jazyka českého")
Cs1.search_languages = [Language::Czech]
Cs1.entries["ten"] = TextEntry.new("ukazovací zájmeno")

En1 = FakeDictionary.new("ted", "Testford English Dictionary")
En1.search_languages = [Language::English]
En1.entries["ten"] = TextEntry.new("the numeral 10")
En1.entries["tea"] = TextEntry.new("a drink")

En2 = FakeDictionary.new("neud", "The New English Universal Dictionary")
En2.search_languages = [Language::English]
En2.entries["ten"] = TextEntry.new("something between nine and eleven")
