require "spec"

require "../src/markup.cr"
require "../src/term.cr"
require "./lipsum.cr"

include Diclionary
include Diclionary::Text

wrap_80 = TerminalStyle.new
wrap_80.line_width = 80

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

	# Ensure newlines are not interpreted in failure messages.
	def inspect()
		"\n" + self
	end
end

describe LineWrapper do
	it "enables setting the line width and margins" do
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
	it "prints text with configurable line width and margins" do
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

describe "#format" do
	context "in default configuration" do
		it "does not wrap lines" do
			formatted = String.build {|io| format Lipsum[0], io}
			formatted.each_line.size.should eq 1
			formatted = String.build {|io| format Lipsum[1], io}
			formatted.each_line.size.should eq 1
			formatted = String.build {|io| format Lipsum[2], io}
			formatted.each_line.size.should eq 1
		end
	end
	context "when configured to justify lines to 80 characters" do
		it "stretches plain text to fill lines" do
			m = markup(<<-TEXT)
				Lorem ipsum dolor sit amet, consectetur adipiscing elit. \
				Etiam nec tortor id magna vulputate pretium.
				TEXT
			formatted = String.build {|io| format m, io, just_80}
			formatted.should_be_justified(80)
		end
		it "stretches multi-part text to fill lines" do
			m = markup(
				"Lorem ipsum dolor sit amet, consectetur adipiscing elit. ",
				"Etiam nec tortor id ", "magna", " vulputate pretium.")
			formatted = String.build {|io| format m, io, just_80}
			formatted.should_be_justified(80)
		end
		it "stretches marked-up text to fill lines" do
			m = markup(
				"Lorem ipsum dolor sit amet, consectetur adipiscing elit. ",
				"Etiam nec tortor id ", bold("magna"), " vulputate pretium.")
			formatted = String.build {|io| format m, io, just_80}
			formatted.should_be_justified(80)
		end
		it "stretches a plain paragraph to fill lines" do
			m = Lipsum[0]
			formatted = String.build {|io| format m, io, just_80}
			formatted.should_be_justified(80)
		end
		it "stretches marked-up paragraph to fill lines" do
			m = Lipsum[1]
			formatted = String.build {|io| format m, io, just_80}
			formatted.should_be_justified(80)
			m = Lipsum[2]
			formatted = String.build {|io| format m, io, just_80}
			formatted.should_be_justified(80)
		end
	end
	context "when configured to justify to custom width" do
		it "stretches text to configured width" do
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
	end
	context "configured with margins" do
		it "prints normal text with margins" do
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
	end
end

describe Paragraph do
	it "is separated from surrounding text and paragraphs by blank lines" do
		style = TerminalStyle.new()
		style.line_width = 40
		m = markup("Line outside paragraph.",
			paragraph(<<-PAR),
				This is the beginning of a paragraph. \
				Lorem ipsum dolor sit amet, consectetur adipiscing elit.
				PAR
			paragraph(<<-PAR),
				This is a second paragraph. \
				Fusce sed condimentum neque, nec aliquam magna. \
				Maecenas et mollis risus, in facilisis nisl.
				PAR
			"Outside paragraph again.")
		formatted = String.build {|io| format m, io, style}
		formatted.should eq <<-EXPECTED
			Line outside paragraph.

			This is the beginning of a paragraph.
			Lorem ipsum dolor sit amet, consectetur
			adipiscing elit.

			This is a second paragraph. Fusce sed
			condimentum neque, nec aliquam magna.
			Maecenas et mollis risus, in facilisis
			nisl.

			Outside paragraph again.

			EXPECTED
			#-------------- 40 chars --------------#
	end
	it "can have the first line indented" do
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
	context "when line length is not set" do
		pending "is separated from surrounding text by blank lines" do
			style = TerminalStyle.new()
			m = markup("Line outside paragraph.",
				paragraph(<<-PAR),
					This is the beginning of a paragraph. \
					Lorem ipsum dolor sit amet, consectetur adipiscing elit.
					PAR
				"Outside paragraph again.")
			formatted = String.build {|io| format m, io, style}
			formatted.should eq <<-EXPECTED
				Line outside paragraph.

				This is the beginning of a paragraph. Lorem ipsum dolor sit amet, consectetur adipiscing elit.

				Outside paragraph again.

				EXPECTED
		end
	end
	context "when line length is set" do
		it "is separated from surrounding text by blank lines" do
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
	end
end

describe OrderedList do
	it "prints list items on new lines with indent" do
		formatted = String.build {|io| format Lipsum[3], io, wrap_80}
		formatted.should eq <<-EXPECTED
			Donec sit amet facilisis lectus. Integer et fringilla velit. Sed aliquam eros ac
			turpis tristique mollis. Maecenas luctus magna ac elit euismod fermentum.
			 1. Curabitur pulvinar purus imperdiet purus fringilla, venenatis facilisis quam
			    efficitur. Nunc justo diam, interdum ut varius a, laoreet ut justo.
			 2. Sed rutrum pulvinar sapien eget feugiat.
			 3. Nulla vulputate mollis nisl eu venenatis. Vestibulum consectetur lorem
			    augue, sed dictum arcu vulputate quis. Phasellus a velit velit. Morbi auctor
			    ante sit amet justo molestie interdum. Fusce sed condimentum neque, nec
			    aliquam magna. Maecenas et mollis risus, in facilisis nisl.
			Proin elementum risus ut leo porttitor tristique. Sed sit amet tellus et velit
			luctus laoreet quis sed urna. Sed dictum fringilla nibh sit amet tempor.

			EXPECTED
			#---------------------------------- 80 chars ----------------------------------#
	end
	it "has configurable style" do
		style = TerminalStyle.new()
		style.line_width = 60
		style.list_indent = 6
		formatted = String.build {|io| format Lipsum[3], io, style}
		formatted.should eq <<-EXPECTED
			Donec sit amet facilisis lectus. Integer et fringilla velit.
			Sed aliquam eros ac turpis tristique mollis. Maecenas luctus
			magna ac elit euismod fermentum.
			   1. Curabitur pulvinar purus imperdiet purus fringilla,
			      venenatis facilisis quam efficitur. Nunc justo diam,
			      interdum ut varius a, laoreet ut justo.
			   2. Sed rutrum pulvinar sapien eget feugiat.
			   3. Nulla vulputate mollis nisl eu venenatis. Vestibulum
			      consectetur lorem augue, sed dictum arcu vulputate
			      quis. Phasellus a velit velit. Morbi auctor ante sit
			      amet justo molestie interdum. Fusce sed condimentum
			      neque, nec aliquam magna. Maecenas et mollis risus, in
			      facilisis nisl.
			Proin elementum risus ut leo porttitor tristique. Sed sit
			amet tellus et velit luctus laoreet quis sed urna. Sed
			dictum fringilla nibh sit amet tempor.

			EXPECTED
			#------------------------ 60 chars ------------------------#
	end
	it "indents list items with 'list indent' in addition to margins" do
		style = TerminalStyle.new()
		style.line_width = 64
		style.left_margin = 2
		style.right_margin = 2
		style.list_indent = 6
		formatted = String.build {|io| format Lipsum[3], io, style}
		formatted.should eq <<-EXPECTED
			  Donec sit amet facilisis lectus. Integer et fringilla velit.
			  Sed aliquam eros ac turpis tristique mollis. Maecenas luctus
			  magna ac elit euismod fermentum.
			     1. Curabitur pulvinar purus imperdiet purus fringilla,
			        venenatis facilisis quam efficitur. Nunc justo diam,
			        interdum ut varius a, laoreet ut justo.
			     2. Sed rutrum pulvinar sapien eget feugiat.
			     3. Nulla vulputate mollis nisl eu venenatis. Vestibulum
			        consectetur lorem augue, sed dictum arcu vulputate
			        quis. Phasellus a velit velit. Morbi auctor ante sit
			        amet justo molestie interdum. Fusce sed condimentum
			        neque, nec aliquam magna. Maecenas et mollis risus, in
			        facilisis nisl.
			  Proin elementum risus ut leo porttitor tristique. Sed sit
			  amet tellus et velit luctus laoreet quis sed urna. Sed
			  dictum fringilla nibh sit amet tempor.

			EXPECTED
			#-------------------------- 64 chars --------------------------#
	end
	it "wraps list items so they do not overflow into margins" do
		style = TerminalStyle.new()
		style.line_width = 64
		style.left_margin = 2
		style.right_margin = 2
		style.list_indent = 6
		list = markup("x " * 36, ordered_list(
			item("x " * 40), item("x " * 5), item("x " * 40)))
		formatted = String.build {|io| format list, io, style}
		formatted.should eq <<-EXPECTED
			  x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x
			  x x x x x x
			     1. x x x x x x x x x x x x x x x x x x x x x x x x x x x
			        x x x x x x x x x x x x x
			     2. x x x x x
			     3. x x x x x x x x x x x x x x x x x x x x x x x x x x x
			        x x x x x x x x x x x x x

			EXPECTED
			#-------------------------- 64 chars --------------------------#
	end
	context "configured with markers aligned right" do
		it "wraps list items so they do not overflow into margins" do
			style = TerminalStyle.new()
			style.line_width = 40
			style.list_indent = 8
			style.list_marker_alignment = Alignment::Right
			list = markup("x " * 24, ordered_list(
				item("x " * 5), item("x " * 20)))
			formatted = String.build {|io| format list, io, style}
			formatted.should eq <<-EXPECTED
				x x x x x x x x x x x x x x x x x x x x
				x x x x
				     1. x x x x x
				     2. x x x x x x x x x x x x x x x x
				        x x x x

				EXPECTED
				#-------------- 40 chars --------------#
		end
	end
	context "with many items" do
		it "keeps items with longer label aligned" do
			m = ordered_list(
			item("Nulla"),
			item("vulputate"),
			item("mollis"),
			item("nisl"),
			item("eu"),
			item("venenatis"),
			item("vestibulum"),
			item("consectetur"),
			item("lorem"),
			item("augue"),
			item("sed"),
			item("dictum"))
			formatted = String.build {|io| format m, io, wrap_80}
			formatted.should eq <<-EXPECTED + "\n"
				 1. Nulla
				 2. vulputate
				 3. mollis
				 4. nisl
				 5. eu
				 6. venenatis
				 7. vestibulum
				 8. consectetur
				 9. lorem
				10. augue
				11. sed
				12. dictum
				EXPECTED
		end
		context "with a nested list" do
			it "prints list items on new lines with indent" do
				formatted = String.build {|io| format Lipsum[4], io, wrap_80}
				formatted.should eq <<-EXPECTED
					Donec sit amet facilisis lectus. Integer et fringilla velit. Sed aliquam eros ac
					turpis tristique mollis. Maecenas luctus magna ac elit euismod fermentum.
					 1. Curabitur pulvinar purus imperdiet purus fringilla, venenatis facilisis quam
					    efficitur. Nunc justo diam, interdum ut varius a, laoreet ut justo.
					     1. Integer velit diam, egestas non nisi ut, accumsan ornare eros. Aliquam
					        rhoncus elementum cursus. Quisque vitae blandit ligula.
					     2. Mauris et pellentesque nisi. Aenean nec felis elit. Sed sit amet tellus
					        et velit luctus laoreet quis sed urna. Sed dictum fringilla nibh sit
					        amet tempor. Nam vel sem tincidunt, tempor turpis ac, cursus mauris.
					 2. Sed rutrum pulvinar sapien eget feugiat.
					 3. Nulla vulputate mollis nisl eu venenatis. Vestibulum consectetur lorem
					    augue, sed dictum arcu vulputate quis. Phasellus a velit velit. Morbi auctor
					    ante sit amet justo molestie interdum. Fusce sed condimentum neque, nec
					    aliquam magna. Maecenas et mollis risus, in facilisis nisl.
					Proin elementum risus ut leo porttitor tristique. Sed sit amet tellus et velit
					luctus laoreet quis sed urna. Sed dictum fringilla nibh sit amet tempor.

					EXPECTED
					#---------------------------------- 80 chars ----------------------------------#
			end
			it "indents list items with 'list indent' in addition to margins" do
				style = TerminalStyle.new()
				style.line_width = 64
				style.left_margin = 2
				style.right_margin = 2
				style.list_indent = 6
				formatted = String.build {|io| format Lipsum[4], io, style}
				formatted.should eq <<-EXPECTED
					  Donec sit amet facilisis lectus. Integer et fringilla velit.
					  Sed aliquam eros ac turpis tristique mollis. Maecenas luctus
					  magna ac elit euismod fermentum.
					     1. Curabitur pulvinar purus imperdiet purus fringilla,
					        venenatis facilisis quam efficitur. Nunc justo diam,
					        interdum ut varius a, laoreet ut justo.
					           1. Integer velit diam, egestas non nisi ut,
					              accumsan ornare eros. Aliquam rhoncus elementum
					              cursus. Quisque vitae blandit ligula.
					           2. Mauris et pellentesque nisi. Aenean nec felis
					              elit. Sed sit amet tellus et velit luctus
					              laoreet quis sed urna. Sed dictum fringilla nibh
					              sit amet tempor. Nam vel sem tincidunt, tempor
					              turpis ac, cursus mauris.
					     2. Sed rutrum pulvinar sapien eget feugiat.
					     3. Nulla vulputate mollis nisl eu venenatis. Vestibulum
					        consectetur lorem augue, sed dictum arcu vulputate
					        quis. Phasellus a velit velit. Morbi auctor ante sit
					        amet justo molestie interdum. Fusce sed condimentum
					        neque, nec aliquam magna. Maecenas et mollis risus, in
					        facilisis nisl.
					  Proin elementum risus ut leo porttitor tristique. Sed sit
					  amet tellus et velit luctus laoreet quis sed urna. Sed
					  dictum fringilla nibh sit amet tempor.

					EXPECTED
					#-------------------------- 64 chars --------------------------#
			end
		end
	end
	context "configured with markers aligned left" do
		it "wraps list items so they do not overflow into margins" do
			style = TerminalStyle.new()
			style.line_width = 40
			style.list_indent = 8
			style.list_marker_alignment = Alignment::Left
			list = markup("x " * 24, ordered_list(
				item("x " * 5), item("x " * 20)))
			formatted = String.build {|io| format list, io, style}
			formatted.should eq <<-EXPECTED
				x x x x x x x x x x x x x x x x x x x x
				x x x x
				1.      x x x x x
				2.      x x x x x x x x x x x x x x x x
				        x x x x

				EXPECTED
				#-------------- 40 chars --------------#
		end
	end
	# it "can stretch several paragraphs to fill lines" do
	# 	formatted = String.build {|io| format Lipsum, io}
	# 	formatted.should_be_justified(80)
	# end
end

describe Item do
	it "produces an error if not in a list" do
		m = markup(item("Item outside of a list"))
		expect_raises(Exception, "Item without enclosing list") do
			String.build {|io| format m, io, wrap_80}
		end
	end
end

describe LabeledParagraph do
	it "has a left-aligned label and an indented body" do
		style = TerminalStyle.new()
		style.line_width = 60
		m = markup(
			Lipsum[3][0],
			labeled_paragraph("Lorem Ipsum", Lipsum[0], indent: 4)
		)
		formatted = String.build {|io| format m, io, style}
		formatted.should eq <<-EXPECTED
			Donec sit amet facilisis lectus. Integer et fringilla velit.

			Lorem Ipsum
			    Lorem ipsum dolor sit amet, consectetur adipiscing elit.
			    Etiam nec tortor id magna vulputate pretium. Suspendisse
			    porta bibendum malesuada. Integer velit diam, egestas
			    non nisi ut, accumsan ornare eros. Aliquam rhoncus
			    elementum cursus. Quisque vitae blandit ligula. Proin
			    elit turpis, ornare et malesuada at, mattis in sem.
			    Aliquam tortor lectus, convallis sit amet tristique ac,
			    rhoncus eu lectus. Pellentesque tempus eleifend eros in
			    elementum. Mauris et pellentesque nisi. Aenean nec felis
			    elit. Sed sit amet tellus et velit luctus laoreet quis
			    sed urna. Sed dictum fringilla nibh sit amet tempor. Nam
			    vel sem tincidunt, tempor turpis ac, cursus mauris.

			EXPECTED
			#------------------------ 60 chars ------------------------#
	end
	it "has a short label in line with the first line of the body" do
		style = TerminalStyle.new()
		style.line_width = 60
		m = LabeledParagraph.new "-v", Lipsum[3][0], indent: 4
		formatted = String.build {|io| format m, io, style}
		formatted.should eq <<-EXPECTED
			-v  Donec sit amet facilisis lectus. Integer et fringilla
			    velit.

			EXPECTED
			#------------------------ 60 chars ------------------------#
	end
	pending "is separated from other labeled paragraphs by a blank line" do
		style = TerminalStyle.new()
		style.line_width = 60
		m = markup(
			# labeled_paragraph("Lo", Lipsum[3][3][0].text, indent: 4),
			# labeled_paragraph("Lorem Ipsum", Lipsum[3][3][0].text, indent: 4),
			labeled_paragraph("Lorem Ipsum", Lipsum[3][3][0].text, indent: 4),
			labeled_paragraph("Dolor", Lipsum[3][3][1].text, indent: 4),
			labeled_paragraph("Sit", Lipsum[3][3][2].text, indent: 4),
			labeled_paragraph("Amet", Lipsum[3][3][0].text, indent: 4)
		)
		formatted = String.build {|io| format m, io, style}
		formatted.should eq <<-EXPECTED
			Lorem Ipsum
			    Curabitur pulvinar purus imperdiet purus fringilla,
			    venenatis facilisis quam efficitur. Nunc justo diam,
			    interdum ut varius a, laoreet ut justo.

			Dolor
			    Sed rutrum pulvinar sapien eget feugiat.

			Sit Nulla vulputate mollis nisl eu venenatis. Vestibulum
			    consectetur lorem augue, sed dictum arcu vulputate quis.
			    Phasellus a velit velit. Morbi auctor ante sit amet
			    justo molestie interdum. Fusce sed condimentum neque,
			    nec aliquam magna. Maecenas et mollis risus, in
			    facilisis nisl.

			Amet
			    Curabitur pulvinar purus imperdiet purus fringilla,
			    venenatis facilisis quam efficitur. Nunc justo diam,
			    interdum ut varius a, laoreet ut justo.

			EXPECTED
			#------------------------ 60 chars ------------------------#
	end
end
