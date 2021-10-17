require "./lipsum.cr"

include Diclionary

struct FakeDictionary < Dictionary
	getter entries = Hash(String, Entry).new

	def search(word, format) : SearchResult
		if @entries.has_key? word
			SearchResult.new(@entries[word])
		else
			SearchResult.new
		end
	end
end

Cs1 = FakeDictionary.new("zsjc", "Zkušební slovník jazyka českého")
Cs1.entries["ten"] = TextEntry.new("ukazovací zájmeno")

En1 = FakeDictionary.new("ted", "Testford English Dictionary")
En1.entries["ten"] = TextEntry.new("the numeral 10")
