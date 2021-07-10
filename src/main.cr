require "colorize"
require "log"
require "option_parser"

require "./core.cr"
require "./ssjc.cr"

# Setup logging
# Log.define_formatter Fmt, "#{source}: #{message}"
Log.define_formatter Fmt, "#{message}"
# Use 'Sync' dispatch mode to ensure correct interleaving with output
log_backend = Log::IOBackend.new(io: STDERR, formatter: Fmt, dispatcher: :sync)
Log.setup("*", :warn, log_backend)

log_level = Log::Severity::Notice
format : Format = Format::Text
termwidth = term_width
words = [] of String

parser = OptionParser.new do |p|
	p.on "-v", "--verbose", "Increase verbosity" do
		# Decrease logging level, if possible.
		lvl = log_level.value
		if lvl >= 1
			log_level = Log::Severity.from_value(lvl - 1)
		end
	end
	p.on "--plain", "Output in plain text format" do
		format = Format::Text
	end
	p.on "--structured", "Output in structured format" do
		format = Format::Structured
	end
end
parser.unknown_args do |args|
	if args.size > 0
		words = args
	end
end
parser.parse
Log.setup("xxx", log_level, log_backend)
logger = ::Log.for("xxx")

if words.empty?
	logger.error {"No word given"}
	exit 1
end

channel = Channel(TextEntry | StructuredEntry).new
dd = [SsjcDictionary.new]
dd.each do |d|
	words.each do |word|
		spawn do
			logger.debug {"Searching for '#{word}'."}
			entry = d.search(word, format)
			channel.send(entry)
		end
	end
	Colorize.on_tty_only!
	s = words.size
	s.times do
		entry = channel.receive
		logger.debug {"Displaying entry..."}
		if entry.is_a? TextEntry
			format_text(STDOUT, entry.text, width: termwidth, justify: true)
		else
			puts entry
		end
		puts ""
	end
end
