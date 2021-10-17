require "spec"

require "../src/cli.cr"
require "./dictionaries.cr"

class Tty < String::Builder
	def tty?
		true
	end
end

def run(args : Array(String), tty = true)
	stdout : IO
	stderr : IO
	if tty
		stdout = Tty.new
		stderr = Tty.new
	else
		stdout = String::Builder.new
		stderr = String::Builder.new
	end
	exit_code = Diclionary::Cli.run(args, stdout, stderr)
	{stdout.to_s, stderr.to_s, exit_code}
end

def run(*args : String, tty = true)
	run(args.to_a, tty: tty)
end

Dicts = [] of Diclionary::Dictionary
module Diclionary
	def init_dictionaries(config : Diclionary::Config) : Array(Diclionary::Dictionary)
		Dicts
	end
end

Spec.before_each do
	Dicts.clear
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
	context "ten" do
		it "searches the word 'ten' in all available dictionaries" do
			Dicts << Cs1
			Dicts << En1
			o, e, c = run("ten")
			o.includes?("ukazovací zájmeno").should be_true
			o.includes?("the numeral 10").should be_true
		end
	end
end
