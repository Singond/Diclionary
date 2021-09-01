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
		def initialize(@value : Array(Markup) = [] of Markup)
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

	def markup()
		Base.new()
	end

	private def to_markup(*content : Markup | String) : Array(Markup)
		value = [] of Markup
		content.each do |elem|
			case elem
				in Markup
				value << elem
				in String
				value << PlainText.new(elem)
			end
		end
		value
	end

	def markup(*content : Markup | String)
		Base.new(to_markup(*content))
	end

	struct Bold < Container
		def to_html(io : IO)
			io << "<b>"
			super
			io << "</b>"
		end
	end

	def bold(*content : Markup | String)
		Bold.new(to_markup(*content))
	end
end
