require "spec"

require "../src/cli.cr"

def run(args = [] of String)
	stdout = String::Builder.new
	stderr = String::Builder.new
	exit_code = Diclionary::Cli.run(args, stdout, stderr)
	{stdout.to_s, stderr.to_s, exit_code}
end

describe "#run" do
	context "without arguments" do
		it "fails" do
			output, err, exit_code = run()
			output.should be_empty
			err.should_not be_empty
			exit_code.should eq Diclionary::ExitCode::BadUsage
		end
	end
end
