require "log"
require "option_parser"

require "./core.cr"
require "./ssjc.cr"

# Log.define_formatter Fmt, "#{source}: #{message}"
Log.define_formatter Fmt, "#{message}"
Log.setup("*", :warn, Log::IOBackend.new(formatter: Fmt))
log_level = Log::Severity::Notice

word = ""

parser = OptionParser.new do |p|
	p.on "-v", "--verbose", "Increase verbosity" do
		# Decrease logging level, if possible.
		lvl = log_level.value
		if lvl >= 1
			log_level = Log::Severity.from_value(lvl - 1)
		end
	end
end
parser.unknown_args do |args|
	if args.size > 0
		word = args[0]
	end
end
parser.parse
Log.setup("xxx", log_level, Log::IOBackend.new(formatter: Fmt))
logger = ::Log.for("xxx")

if word.empty?
	logger.error {"No word given"}
	exit 1
else
	logger.debug {"Searching for '#{word}'"}
end

dd = [SsjcDictionary.new]
dd.each do |d|
	entry : Entry = d.search(word)
	puts entry
end
