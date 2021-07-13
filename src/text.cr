require "colorize"
require "string_scanner"

struct FormattedString
	def initialize(@text : String, @format : FormattedString::Format)
	end

	def text
		@text
	end

	def text=(text : String)
		@text = text
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

	def size
		@text.size
	end

	def rstrip
		FormattedString.new(@text.rstrip, @format)
	end

	def to_s(io : IO)
		o = @text
		if bold?
			o = o.colorize.bold
		end
		if dim?
			o = o.colorize.dim
		end
		io << o
	end
end

class TextFormatter
	def initialize(@io : IO, @width : Int32, @justify : Bool)
		@jwidth = @justify ? @width : 0
		@length = 0
		@words = [] of String | FormattedString
	end

	def append(word : String | FormattedString, word_size, trailing_spaces : String)
		if (@length + word_size - trailing_spaces.size) > @width
			print_line(@io, @words, @jwidth)
			@words = [word] of String | FormattedString
			@length = word_size
		else
			@words << word
			if trailing_spaces.includes?("\n")
				print_line(@io, @words)   # Always ragged left
				@words = [] of String | FormattedString
				@length = 0
			else
				@length += word_size
			end
		end
	end

	def flush
		print_line(@io, @words)
	end
end

def format_text(io : IO, text : String, width = 80, justify = false)
	f = TextFormatter.new(io, width, justify)
	s = StringScanner.new(text)
	until s.eos?
		word = s.scan_until(/\s+/)
		if !word
			word = s.rest
			s.terminate
		end
		trailing_spaces = s[0]? || ""
		f.append(word, word.size, trailing_spaces)
	end
	f.flush
end

def format_text(io : IO, strings : Array(FormattedString),
		width = 80, justify = false)
	f = TextFormatter.new(io, width, justify)
	strings.each do |fstring|
		s = StringScanner.new(fstring.text)
		until s.eos?
			word = s.scan_until(/\s+/)
			if !word
				word = s.rest
				s.terminate
			end
			trailing_spaces = s[0]? || ""
			fword = fstring.dup
			fword.text = word
			f.append(fword, word.size, trailing_spaces)
		end
	end
	f.flush
end

def print_line(io : IO, words : Array(String|FormattedString), justify = 0)
	# Remove trailing whitespace:
	words[-1] = words[-1].rstrip

	base = 0
	extra = 0
	every = 0
	if justify > 0
		len = words.reduce(0) {|len, w| len + w.size}
		if (justify > len) && (words.size > 1)
			spaces = justify - len
			base = spaces // (words.size - 1)
			extra = spaces % (words.size - 1)
			if extra != 0
				every = (words.size - 1) // extra
			end
		end
	end
	words.each_with_index(1) do |w, idx|
		io << w
		if (every > 0) && (idx % every == 0) && ((idx / every) <= extra)
			io << " " * (base + 1)
		else
			io << " " * (base)
		end
	end
	io << "\n"
end
