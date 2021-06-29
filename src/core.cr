require "colorize"
require "string_scanner"

enum Format
	Text
	Structured
end

class TextEntry
	property text : Array(FormattedText)

	def initialize()
		@text = [] of FormattedText
	end

	def to_s(io : IO)
		@text.each do |t|
			o = t.text
			if t.bold?
				o = o.colorize.bold
			end
			if t.dim?
				o = o.colorize.dim
			end
			io << o
		end
	end
end

class StructuredEntry
	property headword : String
	property top_sense : Sense?
	property senses : Array(Sense)

	def initialize(@headword)
		@senses = [] of Sense
	end

	def to_s(io : IO)
		io << @headword.upcase
		io << "\n"
		if (sense = @top_sense) && (!sense.empty?)
			print_sense(io, sense)
		end
		@senses.each_with_index(1) do |sense, idx|
			io << "#{idx}) "
			print_sense(io, sense)
		end
	end

	def print_sense(io : IO, sense : Sense)
		io << "Definition: "
		io << sense.definition
		io << "\n"
		io << "Detail: "
		io << sense.text
		io << "\n"
	end
end

class Sense
	property definition : String
	property text : String

	def initialize()
		@definition = ""
		@text = ""
	end

	def to_s(io : IO)
		io << @definition
		io << "\n"
		io << @text
	end

	def empty?
		@definition.empty? && @text.empty?
	end
end

struct FormattedText
	def initialize(@text : String, @format : FormattedText::Format)
	end

	def text
		@text
	end

	def bold?
		@format.bold
	end

	def dim?
		@format.dim
	end

	struct Format
		property bold : Bool
		property dim : Bool

		def initialize
			@bold = false
			@dim = false
		end
	end
end

def format_text(io : IO, text : String, width = 80)
	words = [] of String
	length = 0
	s = StringScanner.new(text)
	until s.eos?
		word = s.scan_until(/\s+/)
		if !word
			break
		end
		if (length + word.size) > width
			print_line(io, words)
			words = [word]
			length = word.size
		else
			words << word
			length += word.size
		end
	end
	print_line(io, words)
end

def print_line(io : IO, words : Array)
	words.each do |w|
		io << w
	end
	io << "\n"
end

def term_width : Int32
	w = ENV["COLUMNS"]?
	if w
		w = w.to_i
	else
		w = 80
	end
end
