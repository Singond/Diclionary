require "../src/languages.cr"
require "../src/main.cr"
require "./spec_helper"

include Diclionary

struct BuggyDictionary < Dictionary
	getter search_languages : Array(Language) = [Language::English]

	def search(word, format) : SearchResult
		#SearchResult.new [TextEntry.new("something")] of Entry
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
				config = Config.new
				config.terms = ["anything"]
				ch = Channel({ExitCode, String}?).new
				spawn do
					stderr = String::Builder.new
					c = Diclionary.run(config, stderr: stderr)
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
