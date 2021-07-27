require "colorize"

require "./text.cr"

VERSION = {{ read_file "version" }}

enum Format
	Text
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
	property log_level = Log::Severity::Notice
	property terms = [] of String
	property format : Format = Format::Text
end

def print_entry(entry : Entry)
	Colorize.on_tty_only!
	justify = false
	width = 0
	if STDOUT.tty? && ENV["TERM"]? != "dumb"
		justify = true
		width = term_width
	end

	case entry
	when TextEntry
		if width > 0
			format_text(STDOUT, entry.text, width: width, justify: justify)
		else
			puts entry
		end
	else
		puts entry
	end
end

def run(config : Config)
	logger = ::Log.for("xxx")
	if config.terms.empty?
		logger.error {"No word given"}
		exit 1
	end

	dd = [SsjcDictionary.new]

	entries = Hash(String, Entry?).new(nil, config.terms.size)
	channel = Channel(Nil).new
	dd.each do |d|
		config.terms.each do |word|
			# For now, assume there is only one dictionary
			entries[word] = nil
			spawn do
				logger.debug {"Searching for '#{word}'."}
				entries[word] = d.search(word, config.format)
				channel.send(nil)
			end
		end
	end
	s = config.terms.size
	s.times do
		channel.receive
	end
	entries.each do |term, entry|
		if entry
			logger.debug {"Displaying entry for '#{term}'..."}
			print_entry(entry)
			puts ""
		else
			logger.notice {"No entry found for '#{term}'"}
		end
	end
end
