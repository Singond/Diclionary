require "./core.cr"
require "./term.cr"
require "./ssjc.cr"

module Diclionary
	def term_width : Int32
		w = ENV["COLUMNS"]?
		if w
			w = w.to_i
		else
			w = 80
		end
	end

	def init_dictionaries(config : Config) : Array(Dictionary)
		all = [Diclionary::Ujc::SSJC] of Dictionary
		all
	end

	def is_applicable?(dict : Dictionary, cfg : Config) : Bool
		return false if cfg.dictionary && dict.name != cfg.dictionary
		l = cfg.search_lang
		return false if l && !dict.search_languages.includes?(l)
		return true
	end

	# Yields all entries in *allresults* to the block.
	private def each_entry(allresults : AllResults, config : Config)
		allresults.each_with_index do |(term, results), i|
			results.each_with_index do |result, j|
				result.entries.each do |entry|
					yield entry, term, result.dictionary
				end
			end
		end
	end

	private def setup_colorize(io : IO, config : Config)
		Colorize.enabled = io.tty? && config.color && ENV["TERM"]? != "dumb"
	end

	def print_entry(entry : Entry, config : Config, io = STDOUT)
		setup_colorize(io, config)
		justify = false
		width = 0
		if io.tty?
			justify = true
			width = term_width
		end

		case entry
		in TextEntry
			style = TerminalStyle.new
			style.left_margin = 2
			style.right_margin = 2
			style.list_marker_alignment = Alignment::Left
			if width > 0
				style.line_width = width
				style.justify = justify
			else
				# A dumb terminal
				style.line_width = 0
			end
			format entry.text, io, style
		in StructuredEntry
			io.puts entry
		end
	end

	def print_results(results : Array(SearchResult), config : Config,
			stdout = STDOUT) : Bool
		did_print = false
		first = true
		results.each do |result|
			Log.debug {"Displaying entry for '#{result.term}'..."}
			stdout.puts "" unless first
			print_entry(result.entry, config, io: stdout)
			did_print = true
			first = false
		end
		did_print
	end

	def run(config : Config, stdout = STDOUT, stderr = STDERR) : ExitCode
		Log.level = config.log_level

		# Handled separately in CLI, kept here for non-CLI usage
		if config.terms.empty?
			Log.error {"No word given"}
			return ExitCode::BadUsage
		end

		all_dictionaries = init_dictionaries(config)
		dictionaries = all_dictionaries.select do |dict|
			is_applicable?(dict, config)
		end
		if all_dictionaries.size > 0 && dictionaries.size == 0
			Log.error {"No dictionaries match the search criteria."}
			return ExitCode::BadConfig
		end

		results = Array(SearchResult).new
		channel = Channel(Nil).new
		fibers = 0
		dictionaries.each do |d|
			config.terms.each do |word|
				fibers += 1
				spawn do
					begin
						Log.debug {"Searching for '#{word}'."}
						results.concat d.search(word, config.format)
						channel.send(nil)
					rescue ex
						stderr.puts ex.message
						channel.send(nil)
					end
				end
			end
		end
		fibers.times do
			channel.receive
		end
		unless print_results(results, config, stdout)
			# No results found
			return ExitCode::NoResult
		end
		ExitCode::Success
	end
end
