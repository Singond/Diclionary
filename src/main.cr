require "log"
require "option_parser"

require "./core.cr"
require "./ssjc.cr"

logger = ::Log.for("*", :warn)

word = ""

parser = OptionParser.new do |p|
	p.on "-v", "--verbose", "Verbose output" do
		logger.level = :info
	end
end
parser.unknown_args do |args|
	if args.size > 0
		word = args[0]
	end
end
parser.parse

if word.empty?
	logger.error {"No word given"}
	exit 1
else
	logger.info {"Searching for '#{word}'"}
end

dd = [SsjcDictionary.new]
dd.each do |d|
	entry : Entry = d.search(word)
	puts entry
end
