require "spec"

require "../src/markup.cr"
require "../src/term.cr"
require "./lipsum.cr"

include Diclionary
include Diclionary::Text

just_80 = TerminalStyle.new
just_80.line_width = 80
just_80.justify = true

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
		it "does not wrap lines by default" do
			formatted = String.build {|io| format Lipsum[0], io}
			formatted.each_line.size.should eq 1
			formatted = String.build {|io| format Lipsum[1], io}
			formatted.each_line.size.should eq 1
			formatted = String.build {|io| format Lipsum[2], io}
			formatted.each_line.size.should eq 1
		end
		it "can stretch plain text to fill lines" do
			m = markup(<<-TEXT)
				Lorem ipsum dolor sit amet, consectetur adipiscing elit. \
				Etiam nec tortor id magna vulputate pretium.
				TEXT
			formatted = String.build {|io| format m, io, just_80}
			formatted.should_be_justified(80)
		end
		it "can stretch multi-part text to fill lines" do
			m = markup(
				"Lorem ipsum dolor sit amet, consectetur adipiscing elit. ",
				"Etiam nec tortor id ", "magna", " vulputate pretium.")
			formatted = String.build {|io| format m, io, just_80}
			formatted.should_be_justified(80)
		end
		it "can stretch marked-up text to fill lines" do
			m = markup(
				"Lorem ipsum dolor sit amet, consectetur adipiscing elit. ",
				"Etiam nec tortor id ", bold("magna"), " vulputate pretium.")
			formatted = String.build {|io| format m, io, just_80}
			formatted.should_be_justified(80)
		end
		it "can stretch plain paragraph to fill lines" do
			m = Lipsum[0]
			formatted = String.build {|io| format m, io, just_80}
			formatted.should_be_justified(80)
		end
		it "can stretch marked-up paragraph to fill lines" do
			m = Lipsum[1]
			formatted = String.build {|io| format m, io, just_80}
			formatted.should_be_justified(80)
			m = Lipsum[2]
			formatted = String.build {|io| format m, io, just_80}
			formatted.should_be_justified(80)
		end
		it "can stretch text to various widths" do
			# To 80 characters
			just = just_80
			formatted = String.build {|io| format Lipsum[1], io, just}
			formatted.should_be_justified(80)
			formatted = String.build {|io| format Lipsum[2], io, just}
			formatted.should_be_justified(80)
			# To 60 characters
			just.line_width = 60
			formatted = String.build {|io| format Lipsum[1], io, just}
			formatted.should_be_justified(60)
			formatted = String.build {|io| format Lipsum[2], io, just}
			formatted.should_be_justified(60)
			# To 40 characters
			just.line_width = 40
			formatted = String.build {|io| format Lipsum[1], io, just}
			formatted.should_be_justified(40)
			formatted = String.build {|io| format Lipsum[2], io, just}
			formatted.should_be_justified(40)
			# To 100 characters
			just.line_width = 100
			formatted = String.build {|io| format Lipsum[1], io, just}
			formatted.should_be_justified(100)
			formatted = String.build {|io| format Lipsum[2], io, just}
			formatted.should_be_justified(100)
		end
		it "can indent the first line of a paragraph" do
			style = just_80
			style.paragraph_indent = 4
			formatted = String.build {|io| format Lipsum[1], io, style}
			formatted.each_line.with_index do |line, number|
				if number == 0
					line.starts_with?("    ").should be_true
				else
					line.starts_with?(" ").should be_false
				end
			end
		end
		it "can print text with margins" do
			style = just_80
			style.paragraph_indent = 2
			style.left_margin = 2
			style.right_margin = 2
			formatted = String.build {|io| format Lipsum[1], io, style}
			formatted.each_line.with_index do |line, number|
				visible = line.gsub(/\e\[[0-9]+m/, "")
				if number == 0
					# First line
					line.starts_with?("    ").should be_true
					visible.strip.size.should eq 74
				elsif number == formatted.lines.size - 1
					# Last line
					line.starts_with?("  ").should be_true
				else
					# Other lines
					line.starts_with?("  ").should be_true
					visible.strip.size.should eq 76
				end
			end
		end
		it "separates paragraphs from surrounding text by blank lines" do
			style = TerminalStyle.new()
			style.line_width = 40
			m = markup("Line outside paragraph.",
				paragraph(<<-PAR),
					This is the beginning of a paragraph. \
					Lorem ipsum dolor sit amet, consectetur adipiscing elit.
					PAR
				"Outside paragraph again.")
			formatted = String.build {|io| format m, io, style}
			formatted.should eq <<-EXPECTED
				Line outside paragraph.

				This is the beginning of a paragraph.
				Lorem ipsum dolor sit amet, consectetur
				adipiscing elit.

				Outside paragraph again.

				EXPECTED
				#-------------- 40 chars --------------#
		end
		# it "can stretch several paragraphs to fill lines" do
		# 	formatted = String.build {|io| format Lipsum, io}
		# 	formatted.should_be_justified(80)
		# end
	end
end

describe LineWrapper do
	it do
		io = IO::Memory.new
		lw = LineWrapper.new(io, 80, true)
		lw.line_width.should eq 80
		lw.left_skip = 2
		lw.line_width.should eq 78
		lw.right_skip = 2
		lw.line_width.should eq 76
		lw.next_left_skip = 2 + 2
		lw.line_width.should eq 74
		lw.write(Printable.new("word"))
		lw.line_width.should eq 74
	end
	it do
		formatted = String.build do |io|
			lw = LineWrapper.new(io, 80, true)
			lw.left_skip = 2
			lw.right_skip = 2
			lw.next_left_skip = 2 + 2
			s = <<-TEXT
				Ut sit amet elementum erat. \
				Morbi auctor ante sit amet justo molestie interdum.
				TEXT
			s.split ' ' do |word|
				lw.write(Printable.new(word))
				lw.write(Whitespace.new(" "))
			end
			lw.flush
		end
		lines = formatted.lines
		lines[0].starts_with?("    ").should be_true
		lines[0].strip.size.should eq 74
	end
end
