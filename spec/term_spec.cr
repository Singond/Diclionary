require "spec"

require "../src/markup.cr"
require "../src/term.cr"
require "./lipsum.cr"

include Diclionary
include Diclionary::Text

class String
	def should_be_wrapped(width : Int32)
		self.each_line do |line|
			line.strip.size.should be <= width
		end
	end
	def should_be_justified(width : Int32)
		l = lines
		l.each_with_index do |line, number|
			next if line.strip.empty?
			printable = line.gsub(/\e\[[0-9]+m/, "")
			printable.strip.size.should be <= width, <<-MSG
				This line exceeds #{width} printable characters:
				#{line.dump}
				|#{"-"*(width)}|
				MSG
			unless number >= (l.size - 1) # Last line
				printable.strip.size.should eq(width), <<-MSG
					This line is not justified to #{width} characters:
					#{line.dump}
					|#{"-"*(width)}|
					MSG
			end
		end
		l.last.size.should be <= width
	end
end

describe Diclionary::Text do
	describe "#format" do
		it "can stretch plain text to fill lines" do
			m = markup(<<-TEXT)
				Lorem ipsum dolor sit amet, consectetur adipiscing elit. \
				Etiam nec tortor id magna vulputate pretium.
				TEXT
			formatted = String.build {|io| format m, io}
			formatted.should_be_justified(80)
		end
		it "can stretch multi-part text to fill lines" do
			m = markup(
				"Lorem ipsum dolor sit amet, consectetur adipiscing elit. ",
				"Etiam nec tortor id ", "magna", " vulputate pretium.")
			formatted = String.build {|io| format m, io}
			formatted.should_be_justified(80)
		end
		it "can stretch marked-up text to fill lines" do
			m = markup(
				"Lorem ipsum dolor sit amet, consectetur adipiscing elit. ",
				"Etiam nec tortor id ", bold("magna"), " vulputate pretium.")
			formatted = String.build {|io| format m, io}
			formatted.should_be_justified(80)
		end
		it "can stretch plain paragraph to fill lines" do
			m = Lipsum[0]
			formatted = String.build {|io| format m, io}
			formatted.should_be_justified(80)
		end
		it "can stretch marked-up paragraph to fill lines" do
			m = Lipsum[1]
			formatted = String.build {|io| format m, io}
			formatted.should_be_justified(80)
			m = Lipsum[2]
			formatted = String.build {|io| format m, io}
			formatted.should_be_justified(80)
		end
		# it "can stretch several paragraphs to fill lines" do
		# 	formatted = String.build {|io| format Lipsum, io}
		# 	formatted.should_be_justified(80)
		# end
	end
end
