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

	class TerminalFormatter
		@style : TerminalStyle
		@io : IO
		@pending_whitespace = ""
		@whitespace_written = false
		@bold = 0
		@italic = 0
		@dim = 0
		@lists = [] of OrderedList | UnorderedList
		@numbering = Deque(Int32).new
		@in_ordered_list = false
		@indentation = Deque(Int32).new
		@lw : LineWrapper

		def initialize(@style, @io = STDOUT)
			@lw = LineWrapper.new(@io, @style.line_width, @style.justify)
			indent(@style.left_margin)
			@lw.right_skip = @style.right_margin
		end

		def format(text : Markup)
			#whitespace_written = false
			text.each do |e, start|
				if start
					@whitespace_written = false
					open(e)
					@pending_whitespace = "" if @whitespace_written
				else
					close(e)
				end
			end
			@lw.flush unless @lw.empty?
		end

		# Increases the default `left_skip` by *amount*.
		private def indent(amount)
			@indentation.push amount
			@lw.left_skip = @indentation.sum
		end

		# Increases the default `left_skip` by *amount*
		# for the next line to be written.
		private def indent_one(amount)
			@lw.next_left_skip = @indentation.sum + amount
		end

		# Decreases the default `left_skip` by the last amount
		# added with `#indent`.
		private def dedent()
			@indentation.pop
			@lw.left_skip = @indentation.sum
		end

		# Prints *label* dedented with respect to current indentation
		# setting.
		#
		# The *rmargin* sets the minimum amount of whitespace between
		# the label and the body (if it starts on the same line).
		private def dedent_label(label : String, levels = 1,
				align = Alignment::Left, rmargin = 1)
			@lw.flush unless @lw.empty?
			white_width = 0
			print_width = 0
			@indentation.each_with_index do |val, idx|
				if idx < @indentation.size - levels
					@io << " " * val
					white_width += val
				else
					print_width += val
				end
			end

			if print_width >= (label.size + rmargin)
				case align
				in Alignment::Left
					@io << label.ljust(print_width)
					# Margin already handled by ljust.
				in Alignment::Center
					# XXX: Offsets the label even when there is enough space.
					# Ignore this issue for now (the center alignment is
					# ugly anyway).
					@io << (label + " " * rmargin).center(print_width)
				in Alignment::Right
					@io << label.rjust(print_width - rmargin)
					@io << " " * rmargin
				end
				@lw.ignore_left_skip(white_width + print_width)
			else
				# Printing on separate line: ignore the separator
				@io << label << "\n"
			end
		end

		private def open(e : PlainText)
			return if e.text.empty?
			c = Colorize.with
			if @bold > 0
				c = c.bold
			end
			if @dim > 0
				c = c.dim
			end
			@io << @pending_whitespace
			@whitespace_written = true
			c.surround(@lw) do
				@lw << "\e[3m" if @italic > 0
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
						@lw.write(Printable.new(word))
						@lw.write(Whitespace.new(trailing_spaces))
					else
						@lw.write(Printable.new(word))
					end
				end
				@lw << "\e[0m" if @italic > 0
			end
		end

		private def open(e : Bold)
			@bold += 1;
		end

		private def close(e : Bold)
			@bold -= 1;
		end

		private def open(e : Italic)
			@italic += 1;
		end

		private def close(e : Italic)
			@italic -= 1;
		end

		private def open(e : Small)
			@dim += 1;
		end

		private def close(e : Small)
			@dim -= 1;
		end

		private def open(e : Paragraph)
			unless @lw.empty?
				@lw.flush
				@pending_whitespace = "\n"
			end
			return if e.text.empty?
			indent_one(@style.paragraph_indent)
			if @pending_whitespace.ends_with? "\n"
				@io << @pending_whitespace
				@whitespace_written = true
			end
		end

		private def close(e : Paragraph)
			@lw.flush unless @lw.empty?
			@pending_whitespace = "\n" unless e.text.empty?
		end

		private def open(e : OrderedList)
			@lw.flush unless @lw.empty?
			indent(@style.list_indent)
			@lists.push e
			@numbering.push 0
		end

		private def close(e : OrderedList)
			@lw.flush unless @lw.empty?
			@numbering.pop unless @numbering.empty?
			@lists.pop unless @lists.empty?
			dedent
		end

		private def open(e : UnorderedList)
			@lw.flush unless @lw.empty?
			indent(@style.list_indent)
			@lists.push e
		end

		private def close(e : UnorderedList)
			@lw.flush unless @lw.empty?
			@lists.pop unless @lists.empty?
			dedent
		end

		private def open(e : Item)
			if @lists.empty?
				raise "Item without enclosing list"
			end
			case @lists[-1]
			when OrderedList
				n = @numbering.pop + 1
				@numbering.push n
				dedent_label("#{n}.", align: @style.list_marker_alignment)
			when UnorderedList
				dedent_label("*", align: @style.list_marker_alignment)
			end
		end

		private def close(e : Item)
			@lw.flush unless @lw.empty?
		end

		private def open(e : LabeledParagraph)
			unless @lw.empty?
				@lw.flush
				@pending_whitespace = "\n"
			end
			if @pending_whitespace.ends_with? "\n"
				@io << @pending_whitespace
				@whitespace_written = true
			end
			indent(e.indent)
			dedent_label(e.label, align: Alignment::Left)
		end

		private def close(e : LabeledParagraph)
			@lw.flush unless @lw.empty?
			@pending_whitespace = "\n"
			dedent
		end

		private def open(e)
			# Default case: Do nothing
		end

		private def close(e)
			# Default case: Do nothing
		end
	end

	# Formats the given *text* for display in terminal.
	def format(text : Markup, io : IO = STDOUT,
			style : TerminalStyle = TerminalStyle::DEFAULT)
		TerminalFormatter.new(style, io).format(text)
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

		# Sets *count* characters of left skip to be ignored (not printed)
		# when the next line is printed.
		#
		# This is like setting `next_left_skip`, but without automatically
		# recalculating the line width.
		def ignore_left_skip(count : Int32)
			if @next_left_skip >= count
				@next_left_skip = @next_left_skip - count
			else
				@next_left_skip = 0
			end
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
