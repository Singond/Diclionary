require "../src/cli.cr"
require "./dictionaries.cr"
require "./spec_helper.cr"

class Tty < String::Builder
	def tty?
		true
	end
end

Log.define_formatter Fmt, "#{message}"
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
	log_backend = Log::IOBackend.new(io: stderr, formatter: Fmt, dispatcher: :sync)
	Log.setup("*", :warn, log_backend)
	exit_code = Diclionary::Cli.run(args, stdout, stderr)
	{stdout.to_s, stderr.to_s, exit_code}
end

def run(*args : String, tty = true)
	run(args.to_a, tty: tty)
end

describe "#run" do
	before_each do
		Diclionary.dictionaries = [Cs1, En1]
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
	context "when searching a word not existing in any dictionary" do
		it "exits with error code" do
			o, e, c = run("xxxxxx")
			o.should be_empty
			e.should be_empty
			c.should eq Diclionary::ExitCode::NoResult
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
	context "ten --dictionary=zsjc" do
		it "searches the meaning  only in the 'zsjc' dictionary" do
			o, e, c = run("ten", "--dictionary=zsjc")
			o.should eq <<-EXPECTED + "\n"
			  ukazovací zájmeno
			EXPECTED
		end
	end
	context "ten --dictionary=ted" do
		it "searches the meaning  only in the 'ted' dictionary" do
			o, e, c = run("ten", "--dictionary=ted")
			o.should eq <<-EXPECTED + "\n"
			  the numeral 10
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
			e.should match /No dictionaries match/
			c.should eq Diclionary::ExitCode::BadConfig
		end
	end
	context "ten --language with an unknown language" do
		it "fails with an error message" do
			o, e, c = run("ten", "--language=xx")
			o.should be_empty
			e.should match /Unknown language: xx/
			c.should eq Diclionary::ExitCode::BadUsage
		end
	end
end
