require "colorize"

require "./text.cr"

module Diclionary
	extend self

	VERSION = {{ read_file "version" }}

	Log = ::Log.for("dicl")

	enum Format
		PlainText
		RichText
		Structured
	end

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

	alias Entry = TextEntry | StructuredEntry

	def term_width : Int32
		w = ENV["COLUMNS"]?
		if w
			w = w.to_i
		else
			w = 80
		end
	end

	struct Config
		property log_level : ::Log::Severity = ::Log::Severity::Notice
		property terms = [] of String
		property format : Format = Format::RichText
	end

	def print_entry(entry : Entry, config : Config)
		Colorize.on_tty_only!
		justify = false
		width = 0
		if STDOUT.tty? && ENV["TERM"]? != "dumb"
			justify = true
			width = term_width
		end

		case entry
		in TextEntry
			if width > 0
				format_text(STDOUT, entry.text, width: width,
					justify: justify, rich: config.format != Format::PlainText)
			else
				# A dumb terminal
				puts entry
			end
		in StructuredEntry
			puts entry
		end
	end

	def run(config : Config)
		Log.level = config.log_level

		if config.terms.empty?
			Log.error {"No word given"}
			exit 1
		end

		dd = [SsjcDictionary.new]

		results = Hash(String, Array(Entry)).new([] of Entry, config.terms.size)
		channel = Channel(Nil).new
		dd.each do |d|
			config.terms.each do |word|
				# For now, assume there is only one dictionary
				results[word] = [] of Entry
				spawn do
					Log.debug {"Searching for '#{word}'."}
					results[word] += d.search(word, config.format)
					channel.send(nil)
				end
			end
		end
		s = config.terms.size
		s.times do
			channel.receive
		end
		results.each do |term, result|
			if !result.empty?
				result.each do |entry|
					Log.debug {"Displaying entry for '#{term}'..."}
					print_entry(entry, config)
					puts ""
				end
			else
				Log.notice {"No entry found for '#{term}'"}
			end
		end
	end
end
