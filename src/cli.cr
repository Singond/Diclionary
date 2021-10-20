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

	private def parse_args(args, stdout = STDOUT, stderr = STDERR) \
			: {Config | ExitCode, OptionParser}
		Log.debug {"Parsing args"}
		config = Config.new
		exit_code = nil
		parser = OptionParser.new do |p|
			p.banner = <<-BANNER
			Usage: dicl [OPTIONS] WORD...

			Options:
			BANNER
			p.on "--version", "Show version number and exit" do
				stdout.puts VERSION
				exit_code = ExitCode::Success
			end
			p.on "-h", "--help", "Print usage and exit" do
				usage(stdout, p)
				exit_code = ExitCode::Success
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
			p.on "-l LANG", "--language=LANG",
					"Search entries in LANG" do |lang|
				config.search_lang = Language.from_code lang
			end
		end
		parser.unknown_args do |args|
			if args.size > 0
				config.terms = args
			end
		end
		parser.parse args

		e = exit_code
		return {e || config, parser}
	end

	def run(args = ARGV, stdout = STDOUT, stderr = STDERR) : ExitCode
		begin
			config, parser = parse_args(args, stdout, stderr)
		rescue e : OptionParser::Exception
			stderr.puts e.message
			return ExitCode::BadUsage
		end

		case config
		in ExitCode
			return config
		in Config
			if config.terms.empty?
				usage(stderr, parser)
				return ExitCode::BadUsage
			end
			Diclionary.run(config, stdout: stdout)
		end
	end
end
