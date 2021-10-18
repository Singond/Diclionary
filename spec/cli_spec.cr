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


describe "#run" do
	before_each do
		Dicts.clear
		Dicts << Cs1
		Dicts << En1
	end

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
			o, e, c = run("ten")
			o.includes?("ukazovací zájmeno").should be_true
			o.includes?("the numeral 10").should be_true
		end
	end
	context "ten, tea" do
		it "prints individual entries separated by a blank line" do
			o, e, c = run("ten", "tea")
			o.should eq <<-EXPECTED + "\n"
			  ukazovací zájmeno

			  the numeral 10

			  a drink
			EXPECTED
		end
	end
	context "ten --language=cs" do
		it "searches the meaning of the Czech word 'ten'" do
			o, e, c = run("ten", "--language=cs")
			o.should eq <<-EXPECTED + "\n"
			  ukazovací zájmeno
			EXPECTED
		end
	end
	context "ten --language=en" do
		it "searches the meaning of the English word 'ten'" do
			o, e, c = run("ten", "--language=en")
			o.should eq <<-EXPECTED + "\n"
			  the numeral 10
			EXPECTED
		end
	end
	context "ten --language for a known language without dictionary" do
		it "does not block indefinitely" do
			o, e, c = run("ten", "--language=de")
		end
		it "fails" do
			o, e, c = run("ten", "--language=de")
			o.should be_empty
			c.should_not eq Diclionary::ExitCode::Success
		end
	end
end
