class Entry
	property headword : String
	property top_sense : Sense?
	property senses : Array(Sense)

	def initialize(@headword)
		@senses = [] of Sense
	end

	def to_s(io : IO)
		io << @headword.upcase
		io << "\n"
		if (top_sense = @top_sense)
			io << top_sense.text
			io << "\n"
		end
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
