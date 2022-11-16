require "colorize"
require "http/client"
require "log"

require "./markup.cr"

module Diclionary
	extend self

	VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}
	BUILD_DATE = {{ `date -u -I`.chomp.stringify }}
	REVISION = {{ env("DICL_GIT_COMMIT") }}

	Log = ::Log.for("dicl")

	enum ExitCode
		Success = 0
		NoResult = 1
		BadUsage = 2
		BadConfig = 3
		Other = 10
	end

	# A connector to a dictionary.
	abstract struct Dictionary
		# Unique machine name
		getter id : String
		# Pretty name
		getter name : String
		# Description
		getter description : String?
		# Author(s)
		getter author : String?
		# Year(s) of publication
		getter year : String?
		# Publisher (if applicable)
		getter publisher : String?
		# Website URL
		getter url : String?

		getter search_languages : Array(Language) = [] of Language

		def initialize(@id = "", @name = "")
		end

		# Searches *word* in the dictionary and returns the results.
		abstract def search(word : String, format : Format) : Array(SearchResult)

		protected def get_url(client : HTTP::Client, path : String)
			Log.info {"Querying '#{client.host}#{path}'"}
			t_start = Time.monotonic
			response = client.get(path)
			t_end = Time.monotonic - t_start
			Log.info {"Got response in #{t_end.total_seconds.round(3)} s."}
			response
		end

		protected def get_url(host : String, path : String)
			client = HTTP::Client.new(host)
			response = get_url(client, path)
			client.close
		end

		def info() : Markup
			m = markup
			if desc = @description
				m.children << paragraph(desc)
			end
			kw = {indent: 8}
			if author = @author
				m.children << labeled_paragraph("Author:", author, **kw)
			end
			publisher = @publisher
			year = @year
			if publisher || year
				body = markup
				body.children << markup(publisher) if publisher
				body.children << markup(", ") if publisher && year
				body.children << markup("#{year}")
				par = LabeledParagraph.new("Published by:", body, **kw)
				m.children << par
			end
			if url = @url
				m.children << labeled_paragraph("URL:", url, **kw)
			end
			m
		end
	end

	struct Language
		property two_letter : String
		property three_letter : String

		def initialize(@two_letter, @three_letter = "")
		end

		def matches_code(code)
			if code.size == 2
				@two_letter == code
			elsif code.size == 3
				@three_letter == code
			else
				false
			end
		end

		def to_s(io : IO)
			unless @two_letter.empty?
				io << @two_letter
			else
				io << @three_letter
			end
		end

		def inspect(io : IO)
			io << '"'
			to_s io
			io << '"'
		end
	end

	enum Format
		PlainText
		RichText
		Structured
	end

	alias Entry = TextEntry | StructuredEntry

	class TextEntry
		property text : Text::Markup

		def initialize(@text = markup())
		end

		def initialize(string : String)
			initialize(markup(string))
		end

		def to_s(io : IO)
			@text.text
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

	# Entry found by searching a dictionary.
	struct SearchResult
		getter entry : Entry
		getter dictionary : Dictionary
		# The search term.
		getter term : String

		def initialize(@entry, @dictionary, @term)
		end
	end

	struct Config
		property log_level : ::Log::Severity = ::Log::Severity::Notice
		property terms = [] of String
		property format : Format = Format::RichText
		property color : Bool = true
		property dictionaries = [] of String
		property search_lang : Language?
	end
end
