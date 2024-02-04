require "./core"
require "./repl"
require "./term"

require "./dictionaries/dict"
require "./dictionaries/psjc"
require "./dictionaries/ssjc"

module Diclionary

	def term_width : Int32
		w = ENV["COLUMNS"]?
		if w
			w = w.to_i
		else
			w = 80
		end
	end

	def all_dictionaries() : Array(Dictionary)
		Log.debug {"Initializing available dictionaries..."}
		[Diclionary::Ujc::SSJC, Diclionary::Ujc::PSJC] of Dictionary
	end

	# Selects elements from *dictionaries* matching *config*,
	# preserving the order in which they were given, if applicable.
	def select_dictionaries(config : Config, dictionaries = all_dictionaries) \
			: Array(Dictionary)
		selected = if config.dictionaries.empty?
			# No dictionary names selected, use all dictionaries
			dictionaries
		else
			# Use only the selected dictionaries in that order
			config.dictionaries.uniq.compact_map do |dict_name|
				dict = dictionaries.find { |d| d.id == dict_name }
				unless dict
					Log.error {"Unknown dictionary '#{dict_name}'."}
					Log.error {"Run 'dicl --list-dictionaries' to see installed dictionaries."}
				end
				dict
			end
		end
		selected.select do |dict|
			is_applicable?(dict, config)
		end
	end

	def is_applicable?(dict : Dictionary, cfg : Config) : Bool
		l = cfg.search_lang
		return false if l && !dict.search_languages.includes?(l)
		return true
	end

	# Yields elements in *results* to the block, grouped by dictionary.
	private def group_by_dict(results : Array(SearchResult), config : Config)
		grouped = Hash(Dictionary, Array(SearchResult)).new
		grouped = results.reduce(grouped) do |acc, r|
			unless acc.has_key?(r.dictionary)
				acc[r.dictionary] = [] of SearchResult
			end
			acc[r.dictionary] << r
			acc
		end
		grouped.keys.each do |key|
			grouped[key].each do |result|
				yield result
			end
		end
	end

	private def setup_colorize(io : IO, config : Config)
		Colorize.enabled = io.tty? && config.color && ENV["TERM"]? != "dumb"
	end

	private def term_style(io : IO, config : Config?) : TerminalStyle
		style = TerminalStyle.new
		style.left_margin = 2
		style.right_margin = 2
		style.list_marker_alignment = Alignment::Left

		justify = false
		width = 0
		if io.tty?
			justify = true
			width = term_width
		end

		if width > 0
			style.line_width = width
			style.justify = justify
		else
			# A dumb terminal
			style.line_width = 0
		end
		style
	end

	# Prints the version information into *io*.
	#
	# The information printed includes the program version and the date
	# it was built.
	#
	# If a configuration object is given and the log level is higher than
	# `Notice`, it includes additional information like the corresponding
	# Git commit hash (provided it was available at compile time).
	def print_version(io = STDOUT, config = nil)
		io << "Diclionary "
		io << VERSION
		io << " ("
		io << BUILD_DATE
		io << ")\n"
		if (config && config.log_level <= ::Log::Severity::Info)
			rev : String? = REVISION
			if rev.is_a? String
				io << "git revision: #{REVISION}\n" if !rev.empty?
			end
		end
	end

	private def print_dictionary_header(dict : Dictionary, io = STDOUT)
		io << dict.name
		if year = dict.year
			io << " (" << year << ")"
		end
		io << "\n"
	end

	def list_dictionaries(dicts : Array(Dictionary), io = STDOUT,
			config : Config? = nil)
		style = term_style(io, config)
		setup_colorize(io, config)
		first = true
		dicts.each do |dict|
			io << "\n\n" unless first
			Colorize.with.blue.surround(io) do
				print_dictionary_header(dict, io)
				io << "[" << dict.id << "]\n"
			end
			format dict.info, io, style
			first = false
		end
	end

	def list_dictionaries(io = STDOUT, config : Config? = nil)
		list_dictionaries(all_dictionaries, io, config)
	end

	# Prints an entry header into *io*.
	#
	# If both *term* and *dict* are `nil`, prints nothing.
	# Returns `true` if anything was printed.
	private def print_header(term : String?, dict : Dictionary?,
			config : Config, io = STDOUT)
		return false unless term || dict
		setup_colorize(io, config)
		Colorize.with.blue.surround(io) do
			if dict
				print_dictionary_header(dict, io)
				io << "\n"
			end
			io << term << "\n\n" if term
		end
		return true
	end

	def print_entry(entry : Entry, config : Config, io = STDOUT)
		setup_colorize(io, config)
		style = term_style(io, config)

		case entry
		in TextEntry
			format entry.text, io, style
		in StructuredEntry
			io.puts entry
		end
	end

	def print_results(results : Array(SearchResult), config : Config,
			stdout = STDOUT, print_term = false, print_dict = false) : Bool
		did_print = false
		prev : SearchResult? = nil
		group_by_dict(results, config) do |result|
			Log.debug {"Displaying entry for '#{result.term}'..."}
			dict_changed = !prev || result.dictionary != prev.dictionary
			term_changed = !prev || result.term != prev.term
			term_changed ||= dict_changed

			# Print header
			stdout.puts "" if prev
			print_header(
				(term_changed && print_term) ? result.term : nil,
				(dict_changed && print_dict) ? result.dictionary : nil,
				config: config,
				io: stdout
			)

			# Print entry
			print_entry(result.entry, config, io: stdout)
			did_print = true
			prev = result
		end
		did_print
	end

	# Searches given *terms* in given *dictionaries*.
	def search_terms(terms : Array(String), dictionaries : Array(Dictionary),
			config : Config)
		results = Array(SearchResult).new
		channel = Channel(Nil).new
		fibers = 0
		dictionaries.each do |d|
			terms.each do |word|
				fibers += 1
				spawn do
					begin
						Log.debug {"Searching for '#{word}'."}
						results.concat d.search(word, config.format)
						channel.send(nil)
					rescue ex
						config.stderr.puts ex.message
						channel.send(nil)
					end
				end
			end
		end
		fibers.times do
			channel.receive
		end
		results
	end

	# Searches given *terms* in given *dictionaries* and prints
	# the results into STDOUT.
	def search_print_terms(
			terms : Array(String), dictionaries : Array(Dictionary),
			config : Config)
		results = search_terms(terms, dictionaries, config)
		print_results(results, config, config.stdout,
				print_term: terms.size > 1,
				print_dict: dictionaries.size > 1)
	end

	def run_once(terms : Array(String), config : Config) : ExitCode
		Log.level = config.log_level

		# Handled separately in CLI, kept here for non-CLI usage
		if terms.empty?
			Log.error {"No word given"}
			return ExitCode::BadUsage
		end

		dictionaries = select_dictionaries(config)
		if dictionaries.size == 0
			Log.error {"No dictionaries match the search criteria."}
			return ExitCode::BadConfig
		end

		did_print = search_print_terms(terms, dictionaries, config)
		if did_print
			ExitCode::Success
		else
			ExitCode::NoResult
		end
	end

	def run_interactive(config : Config) : ExitCode
		dictionaries = select_dictionaries(config)
		if dictionaries.size == 0
			Log.error {"No dictionaries match the search criteria."}
			return ExitCode::BadConfig
		end

		Repl.new(config).run

		ExitCode::Success
	end
end
