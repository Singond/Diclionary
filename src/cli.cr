require "option_parser"

require "./main.cr"

module Diclionary::Cli
	extend self

	private def usage(io : IO, parser : OptionParser)
		io << parser
		io << "\n\n"
		io << "See 'man dicl' for more information."
		io << "\n"
	end

	private enum Mode
		RUN
		LIST_DICTIONARIES
		VERSION
		HELP
	end

	private def parse_args(args, stdout = STDOUT, stderr = STDERR) \
			: {Mode, Config, OptionParser}
		Log.debug {"Parsing args"}
		config = Config.new
		mode = nil
		exit_code = nil
		parser = OptionParser.new do |p|
			p.banner = <<-BANNER
			Usage: dicl [OPTIONS] WORD...

			Options:
			BANNER
			p.on "--version", "Show version number and exit" do
				mode = Mode::VERSION unless mode
			end
			p.on "-h", "--help", "Print usage and exit" do
				mode = Mode::HELP unless mode
			end
			p.on "-v", "--verbose", "Increase verbosity" do
				# Decrease logging level, if possible.
				lvl = config.log_level.value
				if lvl >= 1
					config.log_level = ::Log::Severity.from_value(lvl - 1)
				end
			end
			p.on "--plain", "Output in plain text format" do
				config.format = Format::PlainText
			end
			p.on "--structured", "Output in structured format" do
				config.format = Format::Structured
			end
			p.on "--nocolor", "Disable colored output" do
				Log.debug {"Disabling color output."}
				config.color = false
			end
			p.on "-d DICT", "--dictionary=DICT",
					"Search in dictionary DICT" do |dict_name|
				Log.debug {"Adding dictionary '#{dict_name}'."}
				config.dictionaries << dict_name
			end
			p.on "-l LANG", "--language=LANG",
					"Search entries in LANG" do |lang_code|
				Log.debug {"Setting search language to #{lang_code}."}
				lang = Language.from_code lang_code
				if lang
					config.search_lang = lang
				else
					raise OptionParser::Exception.new(
						"Unknown language '#{lang_code}'.")
				end
			end
			p.on "--list-dictionaries", "List installed dictionaries" do
				mode = Mode::LIST_DICTIONARIES unless mode
			end
		end
		parser.unknown_args do |args|
			if args.size > 0
				config.terms = args
			end
		end
		parser.parse args
		return {(m = mode) ? m : Mode::RUN, config, parser}
	end

	def run(args = ARGV, stdout = STDOUT, stderr = STDERR) : ExitCode
		begin
			mode, config, parser = parse_args(args, stdout, stderr)
		rescue e : OptionParser::Exception
			stderr.puts e.message
			return ExitCode::BadUsage
		end

		case mode
		in Mode::RUN
			if config.terms.empty?
				usage(stderr, parser)
				return ExitCode::BadUsage
			end
			Diclionary.run(config, stdout: stdout, stderr: stderr)
		in Mode::LIST_DICTIONARIES
			Diclionary.list_dictionaries stdout, config
			return ExitCode::Success
		in Mode::HELP
			usage(stdout, parser)
			return ExitCode::Success
		in Mode::VERSION
			Diclionary.print_version(stdout)
			return ExitCode::Success
		end
	end
end
