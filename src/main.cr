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

	def print_entry(entry : Entry, config : Config, io = STDOUT)
		Colorize.on_tty_only!
		justify = false
		width = 0
		if io.tty? && ENV["TERM"]? != "dumb"
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

	def print_results(allresults : AllResults, config : Config,
			stdout = STDOUT) : Bool
		did_print = false
		# print_terms = config.terms.size > 1
		allresults.each_with_index do |(term, results), i|
			# if print_terms
			# 	STDOUT << "[" << term.colorize.bold << "]\n"
			# end
			results.each_with_index do |result, j|
				result.entries.each do |entry|
					Log.debug {"Displaying entry for '#{term}'..."}
					print_entry(entry, config, io: stdout)
					unless i == allresults.size - 1 && j == results.size - 1
						stdout.puts ""
					end
					did_print = true
				end
			end
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

		results = AllResults.new(
			[] of SearchResult, config.terms.size)
		channel = Channel(Nil).new
		fibers = 0
		dictionaries.each do |d|
			config.terms.each do |word|
				results[word] = [] of SearchResult
				fibers += 1
				spawn do
					begin
						Log.debug {"Searching for '#{word}'."}
						results[word] << d.search(word, config.format)
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
