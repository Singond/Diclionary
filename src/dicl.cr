require "colorize"
require "log"
require "option_parser"

require "./core.cr"
require "./ssjc.cr"

include Diclionary

# Setup logging
# Log.define_formatter Fmt, "#{source}: #{message}"
Log.define_formatter Fmt, "#{message}"
# Use 'Sync' dispatch mode to ensure correct interleaving with output
log_backend = Log::IOBackend.new(io: STDERR, formatter: Fmt, dispatcher: :sync)
Log.setup("*", :warn, log_backend)

config = Config.new
parser = OptionParser.new do |p|
	p.on "-v", "--verbose", "Increase verbosity" do
		# Decrease logging level, if possible.
		lvl = config.log_level.value
		if lvl >= 1
			config.log_level = Log::Severity.from_value(lvl - 1)
		end
	end
	p.on "--version", "Show version number and exit" do
		puts VERSION
		exit(0)
	end
	p.on "--plain", "Output in plain text format" do
		config.format = Format::Text
	end
	p.on "--structured", "Output in structured format" do
		config.format = Format::Structured
	end
end
parser.unknown_args do |args|
	if args.size > 0
		config.terms = args
	end
end
begin
	parser.parse
rescue e : OptionParser::Exception
	abort(e.message, 2)
end
Log.setup("xxx", config.log_level, log_backend)
logger = ::Log.for("xxx")

run(config)
