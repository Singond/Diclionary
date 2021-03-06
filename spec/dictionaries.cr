require "../src/languages.cr"
require "./lipsum.cr"

include Diclionary

struct FakeDictionary < Dictionary
	getter entries = Hash(String, Entry).new

	def search_languages=(langs)
		@search_languages = langs
	end

	def search(word, format) : SearchResult
		if @entries.has_key? word
			SearchResult.new(@entries[word])
		else
			SearchResult.new
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
