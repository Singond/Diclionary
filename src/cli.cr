require "option_parser"

require "./main"

module Diclionary::Cli
	extend self

	private def usage(io : IO, parser : OptionParser)
		io << parser
		io << "\n\n"
		io << "See 'man dicl' for more information."
		io << "\n"
	end

	private def parse_args(args, stdout = STDOUT, stderr = STDERR) \
			: {Array(String) | ExitCode, Config}
		Log.debug {"Parsing arguments..."}
		config = Config.new
		config.stdout = stdout
		config.stderr = stderr
		exit_code = nil
		after = nil
		parser = OptionParser.new do |p|
			p.banner = <<-BANNER
			Usage: dicl [OPTIONS] WORD...

			Options:
			BANNER
			p.on "--version", "Show version number and exit" do
				after = -> {
					Diclionary.print_version(stdout, config)
				}
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
				Diclionary.list_dictionaries stdout, config
				exit_code = ExitCode::Success
			end
		end
		parser.parse args
		after.try &.call
		return exit_code || args || [] of String, config
	end

	def run(args = ARGV, stdout = STDOUT, stderr = STDERR) : ExitCode
		begin
			terms, config = parse_args(args, stdout, stderr)
			config.stdout = stdout
			config.stderr = stderr
		rescue e : OptionParser::Exception
			stderr.puts e.message
			return ExitCode::BadUsage
		end

		if terms.is_a? ExitCode
			terms
		elsif args.size > 0
			Diclionary.run_once(terms, config)
		else
			Diclionary.run_interactive(config)
			ExitCode::Success
		end
	end
end
