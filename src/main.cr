require "./core.cr"
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

	def print_results(allresults : AllResults, config : Config) : Bool
		empty = true
		# print_terms = config.terms.size > 1
		allresults.each do |term, results|
			# if print_terms
			# 	STDOUT << "[" << term.colorize.bold << "]\n"
			# end
			results.each do |result|
				result.entries.each do |entry|
					Log.debug {"Displaying entry for '#{term}'..."}
					print_entry(entry, config)
					puts ""
					empty = false
				end
			end
		end
		empty
	end

	def run(config : Config) : ExitCode
		Log.level = config.log_level

		# Handled separately in CLI, kept here for non-CLI usage
		if config.terms.empty?
			Log.error {"No word given"}
			return ExitCode::BadUsage
		end

		dictionaries = init_dictionaries(config)

		results = AllResults.new(
			[] of SearchResult, config.terms.size)
		channel = Channel(Nil).new
		dictionaries.each do |d|
			config.terms.each do |word|
				results[word] = [] of SearchResult
				spawn do
					Log.debug {"Searching for '#{word}'."}
					results[word] << d.search(word, config.format)
					channel.send(nil)
				end
			end
		end
		s = config.terms.size
		s.times do
			channel.receive
		end
		empty = print_results(results, config)
		if empty
			# No results found
			return ExitCode::NoResult
		end
		ExitCode::Success
	end
end
