module Diclionary::Markup
	abstract struct Markup
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

	class MarkupVisitor
		@open : Proc(Markup, Nil) = ->(m : Markup) {}
		@close : Proc(Markup, Nil) = ->(m : Markup) {}

		def open(&block : Markup -> Nil)
			@open = block
		end

		def close(&block : Markup -> Nil)
			@close = block
		end

		def visit(elem : Markup)
			@open.call(elem)
			elem.children.each do |e|
				visit(e)
			end
			@close.call(elem)
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
