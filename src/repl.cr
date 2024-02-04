require "./main"

include Diclionary

class Diclionary::Repl
	@stdin : IO
	@stdout : IO
	@config : Config
	@dictionaries : Array(Dictionary)

	def initialize(@config, @stdin = STDIN, @stdout = STDOUT)
		@dictionaries = select_dictionaries(config)
	end

	private def print_prompt
		@stdout << "dicl> ".colorize(:yellow)
	end

	private def process_line(line)
		if line.in?(":q", ":quit", ":exit")
			return true
		end
		return unless line
		terms = line.split
		did_print = search_print_terms(terms, @dictionaries, @config)
		false
	end

	def run
		quit = false
		until quit
			print_prompt
			quit = process_line(@stdin.gets)
		end
	end
end
