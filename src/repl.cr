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

	enum Command
		Search
		Help
		Exit
	end

	private def print_greeting
		Diclionary.print_version(@stdout, @config)
		@stdout << <<-GREETING << "\n"
		Enter a word to search it in available dictionaries.
		Command prefix is '#{@config.command_prefix}'.
		Type '#{@config.command_prefix}help' for more information.
		Type '#{@config.command_prefix}quit' to exit.
		GREETING
	end

	private def print_prompt
		@stdout << "dicl> ".colorize(:yellow)
	end

	private def parse_line(line)
		if line.starts_with?(@config.command_prefix)
			words = line[1..].split
			command_str = words[0]
			case command_str
			when "help", "h"
				command = Command::Help
			when "exit", "quit", "q"
				command = Command::Exit
			else
				raise "Unknown command: #{command_str}"
			end
			{command, words[1..]?}
		else
			{Command::Search, line.split}
		end
	end

	private def run_command(cmd, args)
		case cmd
		in Command::Search
			return unless args
			did_print = search_print_terms(args, @dictionaries, @config)
		in Command::Help
			@stdout << <<-HELP << "\n"
			Enter one or more words to search them in currently selected dictionaries,
			or type '#{@config.command_prefix}COMMAND' where COMMAND is one of:

			  help, h    Print this help
			  quit, q    Exit the program
			HELP
		in Command::Exit
			# Do nothing, handled elsewhere
		end
	end

	def run
		print_greeting
		quit = false
		until quit
			print_prompt
			return unless line = @stdin.gets
			cmd, args = parse_line(line)
			if cmd == Command::Exit
				quit = true
			else
				run_command(cmd, args)
			end
		end
	end
end
