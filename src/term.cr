require "string_scanner"
require "./markup.cr"

module Diclionary::Text
	extend self

	struct TerminalStyle
		property line_width = 0
		property justify = false
		property paragraph_indent = 0
		property left_margin = 0
		property right_margin = 0
		property list_indent = 4
		property list_marker_alignment = Alignment::Right

		DEFAULT = TerminalStyle.new
	end

	enum Alignment
		Left
		Center
		Right
	end

	# Formats the given *text* for display in terminal.
	def format(text : Markup, io : IO = STDOUT,
			style : TerminalStyle = TerminalStyle::DEFAULT)
		at_start = true
		pending_whitespace = ""
		bold = 0
		italic = 0
		dim = 0
		numbering = Deque(Int32).new
		in_ordered_list = false
		indentation_level = 0

		lw = LineWrapper.new(io, style.line_width, style.justify)
		lw.left_skip = style.left_margin
		lw.right_skip = style.right_margin

		text.each do |e, start|
			if start
				# Entering element 'e'
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
					unless lw.empty?
						lw.flush
						pending_whitespace = "\n"
					end
					lw.next_left_skip = \
							style.left_margin + style.paragraph_indent
					next if e.text.empty?
					if pending_whitespace.ends_with? "\n"
						io << pending_whitespace
						whitespace_written = true
					elsif !at_start
						io << "\n"
					end
				when OrderedList
					unless lw.empty?
						lw.flush
					end
					numbering.push 0
					indentation_level += 1
					lw.left_skip = style.left_margin +
							style.list_indent * indentation_level
				when Item
					n = numbering.pop + 1
					numbering.push n
					indent = style.list_indent * indentation_level
					io << " " * style.left_margin
					case style.list_marker_alignment
					in Alignment::Left
						io << "#{n}. ".ljust(indent)
					in Alignment::Center
						io << "#{n}. ".center(indent)
					in Alignment::Right
						io << "#{n}. ".rjust(indent)
					end
					lw.next_left_skip = 0
					lw.line_width = style.line_width -
							(indent + style.left_margin + style.right_margin)
				end
				pending_whitespace = "" if whitespace_written
			else
				# Leaving element 'e'
				case e
				when Bold
					bold -= 1
				when Italic
					italic -= 1
				when Small
					dim -= 1
				when Paragraph
					lw.flush unless lw.empty?
					pending_whitespace = "\n" unless e.text.empty?
				when OrderedList
					lw.flush unless lw.empty?
					numbering.pop unless numbering.empty?
					indentation_level -= 1
					lw.left_skip = style.left_margin +
							style.list_indent * indentation_level
				when Item
					lw.flush unless lw.empty?
				end
			end
		end
		lw.flush unless lw.empty?
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
		@width : Int32
		@left_skip : Int32 = 0
		@right_skip : Int32 = 0
		property line_width : Int32 = 0
		@next_left_skip : Int32 = 0
		@justify : Bool

		@words = [] of Word
		@words_length = 0
		@nonprintables : Array(Whitespace | Control) = [] of Whitespace | Control
		@nonprintables_length = 0

		def initialize(@io, @width = 0, @justify = false)
			update_widths
		end

		def left_skip=(skip : Int32)
			@left_skip = skip
			@next_left_skip = skip
			update_widths
		end

		def right_skip=(skip : Int32)
			@right_skip = skip
			update_widths
		end

		def next_left_skip=(skip : Int32)
			@next_left_skip = skip
			update_widths
		end

		private def update_widths
			@line_width = @width - (@next_left_skip + @right_skip)
		end

		def read(slice : Bytes)
			@io.read(slice)
		end

		def write(slice : Bytes) : Nil
			if @line_width < 1
				@io.write(slice)
				return
			end

			word = String.build do |io|
				io.write(slice)
			end
			# For now, assume only control sequences
			# are written with this method
			@words << Control.new(word)
			# @words_length += words.last.size
		end

		def write(word : Printable)
			if @line_width < 1
				@io << word.value
			elsif (@words_length + @nonprintables_length + word.length) \
					<= @line_width
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
				print_line(justify: @justify)
				@words << word
				@words_length += word.length
			end
		end

		def write(word : Whitespace | Control)
			if @line_width < 1
				@io << word.value
				return
			end

			@nonprintables << word
			@nonprintables_length += word.length
			# If a newline is included, print the line now, unjustified.
			if word.value.includes?("\n")
				print_line(justify: false)
			end
		end

		private def print_line(justify = false)
			this_left_skip = @next_left_skip
			@next_left_skip = @left_skip
			this_line_width = @line_width
			unless @left_skip == this_left_skip
				update_widths
			end
			@io << " " * this_left_skip
			print_line(@io, @words, justify ? this_line_width : 0)
			@words = [] of Word
			@words_length = 0
			@nonprintables = [] of Whitespace | Control
			@nonprintables_length = 0
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

		def empty?
			@words.empty?
		end

		def flush
			print_line
		end
	end
end
