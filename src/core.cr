require "colorize"
require "log"

require "./text.cr"

module Diclionary
	extend self

	VERSION = {{ read_file "version" }}

	Log = ::Log.for("dicl")

	enum ExitCode
		Success = 0
		NoResult = 1
		BadUsage = 2
		Other = 10
	end

	# A connector to a dictionary.
	abstract struct Dictionary
		def initialize(@name : String = "", @title : String = "")
		end

		# Searches *word* in the dictionary and returns the result.
		abstract def search(word : String, format : Format) : SearchResult
	end

	enum Format
		PlainText
		RichText
		Structured
	end

	alias Entry = TextEntry | StructuredEntry

	class TextEntry
		property text : Array(FormattedString)

		def initialize()
			@text = [] of FormattedString
		end

		def to_s(io : IO)
			@text.each do |t|
				t.to_s(io)
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

	struct SearchResult
		getter entries : Array(Entry)

		def initialize(@entries : Array(Entry))
		end

		def empty?()
			@entries.empty?
		end
	end

	alias AllResults = Hash(String, Array(SearchResult))

	struct Config
		property log_level : ::Log::Severity = ::Log::Severity::Notice
		property terms = [] of String
		property format : Format = Format::RichText
	end
end
