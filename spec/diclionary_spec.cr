require "../src/languages"
require "../src/main"
require "./spec_helper"

include Diclionary

struct BuggyDictionary < Dictionary
	getter search_languages : Array(Language) = [Language::English]

	def search(word, format) : Array(SearchResult)
		raise "The search method failed"
	end
end

describe Diclionary do
	describe ".run" do
		context "when dictionary search raises an exception" do
			before_each do
				Diclionary.dictionaries =
					[BuggyDictionary.new("abd", "Always Buggy Dict")]
			end

			it "shows an error message and returns an error" do
				terms = ["anything"]
				config = Config.new
				ch = Channel({ExitCode, String}?).new
				spawn do
					stderr = String::Builder.new
					config.stderr = stderr
					c = Diclionary.run_once(terms, config)
					ch.send({c, stderr.to_s})
				end
				spawn do
					sleep 2.second
					ch.send(nil)
				end
				if result = ch.receive
					code, stderr = result
					stderr.should_not be_empty, "There is no error message."
					code.should_not eq(ExitCode::Success), "Method returned succes code."
				else
					fail "Method invocation timed out."
				end
			end
		end
	end
end
