require "spec"

require "../src/cli.cr"

def run(args : Array(String))
	stdout = String::Builder.new
	stderr = String::Builder.new
	exit_code = Diclionary::Cli.run(args, stdout, stderr)
	{stdout.to_s, stderr.to_s, exit_code}
end

def run(*args : String)
	run(args.to_a)
end

describe "#run" do
	context "without arguments" do
		it "fails and prints error" do
			output, err, exit_code = run([] of String)
			output.should be_empty
			err.should_not be_empty
			exit_code.should eq Diclionary::ExitCode::BadUsage
		end
	end
	context "--version" do
		it "prints version and exits with succes code" do
			output, err, exit_code = run("--version")
			output.should eq "#{Diclionary::VERSION}\n"
			err.should be_empty
			exit_code.should eq Diclionary::ExitCode::Success
		end
	end
	context "--help" do
		it "prints help and exits with succes code" do
			output, err, exit_code = run("--help")
			output.should match /Usage: dicl .*/
			err.should be_empty
			exit_code.should eq Diclionary::ExitCode::Success
		end
	end
end
