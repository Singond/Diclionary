class Entry
	property headword : String
	property senses : Array(Sense)

	def initialize(@headword)
		@senses = [] of Sense
	end

	def to_s(io : IO)
		@senses.each do |sense|
			io << sense.text
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
