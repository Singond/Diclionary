require "spec"

require "../src/main.cr"

describe Diclionary do
	describe "#run" do
		it "fails if no search terms are given" do
			config = Diclionary::Config.new
			exit_code = Diclionary.run(config)
			exit_code.should eq Diclionary::ExitCode::BadUsage
		end
	end
end
