require "string_scanner"
require "./markup.cr"

module Diclionary::Text
	extend self

	struct TerminalStyle
		DEFAULT = TerminalStyle.new
	end

	# Formats the given *text* for display in terminal.
	def format(text : Markup, io : IO = STDOUT,
			style : TerminalStyle = TerminalStyle::DEFAULT)
		at_start = true
		pending_whitespace = ""
		bold = 0
		italic = 0
		dim = 0

		lw = LineWrapper.new(io, 80, true)

		text.each do |e, start|
			if start
				whitespace_written = false
				case e
				when PlainText
					next if e.text.empty?
					at_start = false
					c = Colorize.with
					if bold > 0
						c = c.bold
					end
					if dim > 0
						c = c.dim
					end
					io << pending_whitespace
					whitespace_written = true
					c.surround(lw) do
						lw << "\e[3m" if italic > 0
						s = StringScanner.new(e.text)
						until s.eos?
							word = s.scan_until(/\s+/)
							if !word
								word = s.rest
								s.terminate
							end
							trailing_spaces = s[0]?
							if trailing_spaces
								word = word[..-(trailing_spaces.size + 1)]
								lw.write(Printable.new(word))
								lw.write(Whitespace.new(trailing_spaces))
							else
								lw.write(Printable.new(word))
							end
						end
						lw << "\e[0m" if italic > 0
					end
				when Bold
					bold += 1
				when Italic
					italic += 1
				when Small
					dim += 1
				when Paragraph
					next if e.text.empty?
					if pending_whitespace.ends_with? "\n\n"
						io << pending_whitespace
						whitespace_written = true
					elsif pending_whitespace.ends_with? "\n"
						io << pending_whitespace
						whitespace_written = true
						io << "\n"
					elsif !at_start
						io << "\n\n"
					end
				end
				pending_whitespace = "" if whitespace_written
			else
				case e
				when Bold
					bold -= 1
				when Italic
					italic -= 1
				when Small
					dim -= 1
				when Paragraph
					lw.flush
					pending_whitespace = "\n\n" unless e.text.empty?
				end
			end
		end
		lw.flush
	end

	private struct Printable
		getter value : String
		getter length : Int32

		def initialize(@value, @length)
		end

		def initialize(@value)
			@length = @value.size
		end

		def inspect(io : IO)
			io << "Printable(#{value.dump}[#{length}])"
		end
	end

	private struct Whitespace
		getter value : String
		getter length : Int32

		def initialize(@value, @length)
		end

		def initialize(@value)
			@length = @value.size
		end

		def inspect(io : IO)
			io << "Whitespace(#{value.dump}[#{length}])"
		end
	end

	private struct Control
		getter value : String
		getter length : Int32 = 0

		def initialize(@value)
		end

		def inspect(io : IO)
			io << "Control(#{value.dump}[#{length}])"
		end
	end

	alias Word = Printable | Whitespace | Control

	private class LineWrapper < IO
		@io : IO
		@line_width : Int32
		@justify_width : Int32
		@words = [] of Word
		@words_length = 0
		@nonprintables : Array(Whitespace | Control) = [] of Whitespace | Control
		@nonprintables_length = 0

		def initialize(@io, @line_width = 0, justify = false)
			@justify_width = justify ? @line_width : 0
		end

		def read(bytes : Bytes)
			@io.read(bytes)
		end

		def write(bytes : Bytes) : Nil
			word = String.build do |io|
				io.write(bytes)
			end
			# For now, assume only control sequences
			# are written with this method
			@words << Control.new(word)
			# @words_length += words.last.size
		end

		def write(word : Printable)
			if (@words_length + @nonprintables_length + word.length) <= @line_width
				# Word fits into the current line width:
				# Just append it to the list of words in current line.
				@words += @nonprintables
				@nonprintables = [] of Whitespace | Control
				@words << word
				@words_length += word.length
			else
				# Word overflows the current line width:
				# Append pending control sequences to the line,
				# print the current line without the word
				# and start a new line with this word.
				@nonprintables.each do |ctrl|
					@words << ctrl if ctrl.is_a? Control
				end
				@nonprintables = [] of Whitespace | Control
				@nonprintables_length = 0
				print_line(@justify_width)
				@words << word
				@words_length += word.length
			end
		end

		def write(word : Whitespace | Control)
			@nonprintables << word
			@nonprintables_length += word.length
			# If a newline is included, print the line now, unjustified.
			if word.value.includes?("\n")
				print_line(justify_width: 0)
			end
		end

		private def print_line(justify_width = 0)
			print_line(@io, @words, justify_width)
			@words = [] of Word
			@words_length = 0
		end

		private def print_line(io : IO, words : Array(Word), justify_width = 0)
			if words.empty?
				return
			end

			# Calculate parameters for justification
			base = 0
			extra = 0
			every = 0
			if justify_width > 0
				len = words.reduce(0) {|len, w| len + w.length}
				stretch = justify_width - len
				if (stretch > 0) #&& (words.size > 1)
					ws = words.select(Whitespace).size
					base = stretch // (ws)
					extra = stretch % (ws)
					if extra != 0
						every = (ws) // extra
					end
				end
			end

			# Print it
			idx = 0
			words.each do |w|
				io << w.value
				# Apply justification by stretching the whitespace sequences
				if w.is_a? Whitespace
					idx += 1
					if (every > 0) \
							&& (idx % every == 0) \
							&& ((idx / every) <= extra)
						io << " " * (base + 1)
					else
						io << " " * (base)
					end
				end
			end
			io << "\n"
		end

		def flush
			print_line
		end
	end
end