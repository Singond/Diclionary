module Diclionary::Text
	abstract struct Markup
		include Enumerable({Markup,Bool})
		include Iterable({Markup,Bool})

		def children
			[] of Markup
		end

		def text(io : IO)
			""
		end

		def text
			String.build do |io|
				text io
			end
		end

		def to_html(io : IO)
			text io
		end

		def to_html
			String.build do |io|
				to_html io
			end
		end

		def inspect(io : IO)
			io << '\\'
			io << self.class.name.split("::").last.downcase
			if !children.empty?
				io << "{"
				children.each do |c|
					c.to_s(io)
				end
				io << "}"
			end
		end

		def each
			iter = HistIterator.new(([self] of Markup).each)
			iters = Deque(HistIterator(Markup)).new
			iters.push iter
			until iters.empty?
				elem = iter.next
				if !elem.is_a?(Iterator::Stop)
					yield({elem, true})
					if elem.children().empty?
						yield({elem, false})
					else
						# Recurse into children
						iter = HistIterator.new(elem.children.each)
						iters.push iter
					end
				else
					# No more leaves in this branch
					if !iters.empty?
						iters.pop
						if !iters.empty?
							# Move to sibling branch
							iter = iters.last
							if last = iter.current
								yield({last, false})
							end
						end
					end
				end
			end
		end

		def each_start
			each do |elem, start|
				next unless start
				yield elem
			end
		end

		def each_end
			each do |elem, start|
				next if start
				yield elem
			end
		end

		def each
			MarkupIterator.new(self)
		end

		def size
			children.size
		end

		def [](index : Int)
			children[index]
		end

		def []?(index : Int)
			children[index]?
		end

		# Converts the rich text into text with ANSI escape codes
		# for display in terminal.
		def to_ansi(io : IO)
			at_start = true
			pending_whitespace = ""

			bold = 0
			italic = 0
			dim = 0
			each do |e, start|
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
						c.surround(io) do
							io << "\e[3m" if italic > 0
							io << e.text
							io << "\e[0m" if italic > 0
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
						pending_whitespace = "\n\n" unless e.text.empty?
					end
				end
			end
		end

		def to_ansi
			String.build do |io|
				to_ansi io
			end
		end
	end

	# A wrapper around an iterator which keeps track of the last
	# element returned by `#next`.
	private class HistIterator(T)
		@current : T? = nil
		def initialize(@iter : Iterator(T))
		end

		def next
			current = @iter.next
			@current = current if current.is_a?(T)
			current
		end

		def current
			@current
		end
	end

	abstract struct Container < Markup
		@value : Array(Markup)
		@@html_tag : String = ""

		def initialize(@value : Array(Markup) = [] of Markup)
		end

		def initialize(*content : Markup | String)
			if content.size == 1
				@value = [to_markup(content[0])] of Markup
			else
				@value = [] of Markup
				content.each do |elem|
					@value << to_markup(elem)
				end
			end
		end

		def children
			@value
		end

		def text(io : IO)
			@value.reduce "" do |alltext, elem|
				io << elem.text
			end
		end

		def to_html(io : IO)
			tag = @@html_tag
			io << "<" << tag << ">" unless tag.empty?
			@value.reduce "" do |alltext, elem|
				io << elem.to_html
			end
			io << "</" << tag << ">" unless tag.empty?
		end
	end

	struct PlainText < Markup
		def initialize(@text : String)
		end

		def text(io : IO)
			io << @text
		end

		def inspect(io : IO)
			io << @text
		end
	end

	struct Base < Container
	end

	private def to_markup(value : Markup | String) : Markup
		case value
		in Markup
			value
		in String
			PlainText.new(value)
		end
	end

	def markup()
		Base.new()
	end

	def markup(*content : Markup | String)
		if content.size == 1
			to_markup(content[0])
		else
			Base.new(*content)
		end
	end

	class MarkupIterator
		include Iterator({Markup, Bool})

		@iters : Deque(HistIterator(Markup))
		@iter : HistIterator(Markup)

		def initialize(markup : Markup)
			@iter = HistIterator.new(([markup] of Markup).each)
			@iters = Deque(HistIterator(Markup)).new
			@iters.push @iter
		end

		def next
			elem = @iter.next
			if !elem.is_a?(Iterator::Stop)
				if !elem.children().empty?
					# Recurse into children
					@iter = HistIterator.new(elem.children.each)
					@iters.push @iter
				end
				return {elem, true}
			else
				# No more leaves in this branch
				if !@iters.empty?
					@iters.pop
					if !@iters.empty?
						# Move to sibling branch
						@iter = @iters.last
						if last = @iter.current
							return {last, false}
						end
					end
				end
			end
			stop
		end
	end

	struct Italic < Container
		@@html_tag = "i"
	end

	def italic(*content : Markup | String)
		Italic.new(*content)
	end

	struct Bold < Container
		@@html_tag = "b"
	end

	def bold(*content : Markup | String)
		Bold.new(*content)
	end

	struct Small < Container
		@@html_tag = "small"
	end

	def small(*content : Markup | String)
		Small.new(*content)
	end

	struct Paragraph < Container
		@@html_tag = "p"
		# def text(io : IO)
		# 	io << "\n\n"
		# 	super
		# end
	end

	def paragraph(*content : Markup | String)
		Paragraph.new(*content)
	end
end
