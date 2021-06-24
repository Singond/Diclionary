class Entry
	property headword : String
	property senses : Array(Sense)

	def initialize(@headword)
		@senses = [] of Sense
	end

	def to_s(io : IO)
		io << @headword.upcase
		io << "\n"
		@senses.each_with_index(1) do |sense, idx|
			io << "#{idx}) "
			io << sense.text
			io << "\n"
		end
	end
end

class Sense
	property text : String

	def initialize()
		@text = ""
	end

	def to_s(io : IO)
		io << @text
	end
end
