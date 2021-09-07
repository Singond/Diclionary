module Diclionary::Markup
	abstract struct Markup
		include Enumerable(Markup)
		include Iterable(Markup)

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
			iter = each()
			while !(elem = iter.next()).is_a? Iterator::Stop
				yield elem
			end
		end

		def each
			MarkupIterator.new(self)
		end
	end

	abstract struct Container < Markup
		@value : Array(Markup)

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
			@value.reduce "" do |alltext, elem|
				io << elem.to_html
			end
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

	class MarkupWalker
		@open : Proc(Markup, Nil) = ->(m : Markup) {}
		@close : Proc(Markup, Nil) = ->(m : Markup) {}

		def open(&block : Markup -> Nil)
			@open = block
		end

		def close(&block : Markup -> Nil)
			@close = block
		end

		def walk(elem : Markup)
			@open.call(elem)
			elem.children.each do |e|
				walk(e)
			end
			@close.call(elem)
		end
	end

	class MarkupIterator
		include Iterator(Markup)

		@iters : Deque(Iterator(Markup))
		@iter : Iterator(Markup)

		def initialize(markup : Markup)
			@iter = [markup].each
			@iters = Deque(Iterator(Markup)).new
			@iters.push @iter
		end

		def next
			elem = @iter.next
			if !elem.is_a?(Iterator::Stop)
				if !elem.children().empty?
					# Recurse into children
					@iter = elem.children.each
					@iters.push @iter
				end
			else
				# No more leaves in this branch
				while elem.is_a?(Iterator::Stop) && !@iters.empty?
					@iters.pop
					if !@iters.empty?
						# Move to sibling branch
						@iter = @iters.last
						elem = @iter.next
					end
				end
			end
			elem
		end
	end

	struct Italic < Container
		def to_html(io : IO)
			io << "<i>"
			super
			io << "</i>"
		end
	end

	def italic(*content : Markup | String)
		Italic.new(*content)
	end

	struct Bold < Container
		def to_html(io : IO)
			io << "<b>"
			super
			io << "</b>"
		end
	end

	def bold(*content : Markup | String)
		Bold.new(*content)
	end
end
