require "spec"

require "../src/markup.cr"

include Diclionary::Text

describe Markup do
	describe "#markup" do
		it "creates instances of Markup" do
			m = markup(bold("text content"))
			m.should be_a Markup
		end
		it "converts strings into PlainText objects" do
			m = markup("text content")
			m.should be_a PlainText
		end
		it "defaults to empty" do
			m = markup()
			m.children.should be_empty
		end
		it "can take multiple arguments" do
			a = markup("A")
			b = markup("B")
			c = markup("C")
			abc = markup(a, b, c)
			abc.should be_a Markup
			abc.children.should eq [a, b, c]
		end
	end
	describe "#text" do
		it "returns the text content of single element" do
			m = markup("this is a text")
			m.text.should eq "this is a text"
		end
		it "returns the concatenated content of multiple elements" do
			m = markup "line ", "with ", "multiple ", "words"
			m.text.should eq "line with multiple words"
		end
	end
	describe "#to_html" do
		it "renders the markup into HTML" do
			m = markup "line with a ", bold("bold"), " word inside"
			m.to_html.should eq "line with a <b>bold</b> word inside"
		end
	end
	describe "#to_s" do
		it "prints the object" do
			markup("a").to_s.should eq "a"
			m = markup("a ", bold("bold and also ", italic("italic")), " text")
			m.to_s.should eq "\\base{a \\bold{bold and also \\italic{italic}} text}"
		end
	end
	describe "#bold" do
		it "is a shorthand for Bold.new" do
			a = bold("some text")
			b = Bold.new("some text")
			a.should eq b
			c = bold("some text", "consisting of", italic("many"), "parts")
			d = Bold.new("some text", "consisting of", italic("many"), "parts")
			c.should eq d
		end
	end
	describe "#to_ansi" do
		it "does not fail when invoked on Markup subtype" do
			markup(paragraph("x"), paragraph("y", "z")).to_ansi
		end
		it "prints the text with ANSI escape codes" do
			m = markup("A text with a ", bold("bold"), " word")
			m.to_ansi.should eq "A text with a \e[1mbold\e[0m word"
			markup("A text with a ", bold("bold"), " and ",
				small("faint"), " word").to_ansi
				.should eq "A text with a \e[1mbold\e[0m and \e[2mfaint\e[0m word"
		end
	end
	describe "#each_start" do
		it "enumerates starting points of each element" do
			a = [] of Markup
			markup("x").each_start {|e| a << e}
			a.should eq [PlainText.new("x")]
			m = markup(markup("x"), "y")
			a = [] of Markup
			m.each_start {|e| a << e}
			a.should eq [m, PlainText.new("x"), PlainText.new("y")]
			m = markup("a", markup("b", "c", markup("d", "e"), "f"))
			a = [] of Markup
			m.each_start {|e| a << e}
			a.should eq [m,
				PlainText.new("a"),
				Base.new(
					PlainText.new("b"),
					PlainText.new("c"),
					Base.new(PlainText.new("d"), PlainText.new("e")),
					PlainText.new("f")),
				PlainText.new("b"),
				PlainText.new("c"),
				Base.new(PlainText.new("d"), PlainText.new("e")),
				PlainText.new("d"),
				PlainText.new("e"),
				PlainText.new("f")]
		end
		it "allows extracting the text content" do
			m = markup("a", bold("b"), "c")
			str = ""
			m.each_start do |e|
				case e
				when PlainText
					str += e.text
				end
			end
			str.should eq "abc"
		end
		it "allows rewriting the tree into another representation" do
			m = markup("a ", bold("bold and also ", italic("italic")), " text")
			str = ""
			m.each do |e, start|
				if start
					case e
					when PlainText
						str += e.text
					when Bold
						str += %q(\textbf{)
					when Italic
						str += %q(\textit{)
					end
				else
					case e
					when Bold, Italic
						str += '}'
					end
				end
			end
			str.should eq %q(a \textbf{bold and also \textit{italic}} text)
		end
	end
	describe "#each_end" do
		it "enumerates ending points of each element" do
			a = [] of Markup
			markup("x").each_end {|e| a << e}
			a.should eq [PlainText.new("x")]
			m = markup(markup("x"), "y")
			a = [] of Markup
			m.each_end {|e| a << e}
			a.should eq [PlainText.new("x"), PlainText.new("y"), m]
			m = markup("a", markup("b", "c", markup("d", "e"), "f"))
			a = [] of Markup
			m.each_end {|e| a << e}
			a.should eq [
				PlainText.new("a"),
				PlainText.new("b"),
				PlainText.new("c"),
				PlainText.new("d"),
				PlainText.new("e"),
				Base.new(PlainText.new("d"), PlainText.new("e")),
				PlainText.new("f"),
				Base.new(
					PlainText.new("b"),
					PlainText.new("c"),
					Base.new(PlainText.new("d"), PlainText.new("e")),
					PlainText.new("f")),
				m]
		end
	end

	it "can be nested" do
		m = markup("a", markup("b", "c", markup("d"), "e"))
		m.children[0].should eq PlainText.new("a")
		m.children[1].should eq Base.new("b", "c", PlainText.new("d"), "e")
		m.children[1].children[0].should eq PlainText.new("b")
		m.children[1].children[1].should eq PlainText.new("c")
		m.children[1].children[2].should eq PlainText.new("d")
		m.children[1].children[3].should eq PlainText.new("e")
	end
	it "is enumerable" do
		m = markup("x")
		a = [] of {Markup, Bool}
		m.each {|t| a << t}
		a.should eq [
			{PlainText.new("x"), true}, {PlainText.new("x"), false}]
		m = markup(markup("x"), "y")
		a = [] of {Markup, Bool}
		m.each {|t| a << t}
		a.should eq [
			{m, true},
			{PlainText.new("x"), true}, {PlainText.new("x"), false},
			{PlainText.new("y"), true}, {PlainText.new("y"), false},
			{m, false}]
		m = markup("a", markup("b", "c", markup("d", "e"), "f"))
		a = [] of {Markup, Bool}
		m.each {|t| a << t}
		a.should eq [
			{m, true},
			{PlainText.new("a"), true},
			{PlainText.new("a"), false},
			{Base.new(
				PlainText.new("b"),
				PlainText.new("c"),
				Base.new(PlainText.new("d"), PlainText.new("e")),
				PlainText.new("f")), true},
			{PlainText.new("b"), true},
			{PlainText.new("b"), false},
			{PlainText.new("c"), true},
			{PlainText.new("c"), false},
			{Base.new(PlainText.new("d"), PlainText.new("e")), true},
			{PlainText.new("d"), true},
			{PlainText.new("d"), false},
			{PlainText.new("e"), true},
			{PlainText.new("e"), false},
			{Base.new(PlainText.new("d"), PlainText.new("e")), false},
			{PlainText.new("f"), true},
			{PlainText.new("f"), false},
			{Base.new(
				PlainText.new("b"),
				PlainText.new("c"),
				Base.new(PlainText.new("d"), PlainText.new("e")),
				PlainText.new("f")), false},
			{m, false}]
	end
	it "supports other Enumerable methods" do
		m = markup("a", markup("b", "c", markup("d"), "e"))
		arr = [] of Markup
		m.each_with_object(arr) do |(elem, start), a|
			a << elem if start
		end
		arr.should eq [m,
			PlainText.new("a"),
			Base.new(
				PlainText.new("b"),
				PlainText.new("c"),
				PlainText.new("d"),
				PlainText.new("e")),
			PlainText.new("b"),
			PlainText.new("c"),
			PlainText.new("d"),
			PlainText.new("e")]
	end
	it "is iterable" do
		markup("x").each.select{|(_, start)| start}.map{|(e,_)| e}
			.to_a.should eq [PlainText.new("x")]
		m = markup(markup("x"), "y")
		m.each.select{|(_, start)| start}.map{|(e,_)| e}
			.to_a.should eq [m, PlainText.new("x"), PlainText.new("y")]
		m = markup("a", markup("b", "c", markup("d", "e"), "f"))
		m.each.select{|(_, start)| start}.map{|(e,_)| e}.to_a.should eq [m,
			PlainText.new("a"),
			Base.new(
				PlainText.new("b"),
				PlainText.new("c"),
				Base.new(PlainText.new("d"), PlainText.new("e")),
				PlainText.new("f")),
			PlainText.new("b"),
			PlainText.new("c"),
			Base.new(PlainText.new("d"), PlainText.new("e")),
			PlainText.new("d"),
			PlainText.new("e"),
			PlainText.new("f")]
	end
	it "can be indexed with []" do
		m = markup("a", markup("b", "c", markup("d", "e"), "f"))
		m.size.should eq 2
		m[0].size.should eq 0
		m[1].size.should eq 4
		m[1][2].size.should eq 2
		m[0].should eq PlainText.new("a")
		m[1].should eq Base.new(PlainText.new("b"),
			PlainText.new("c"),
			Base.new(PlainText.new("d"), PlainText.new("e")),
			PlainText.new("f"))
		m[1][0].should eq PlainText.new("b")
		m[1][1].should eq PlainText.new("c")
		m[1][2].should eq Base.new(PlainText.new("d"), PlainText.new("e"))
		m[1][2][0].should eq PlainText.new("d")
		m[1][2][1].should eq PlainText.new("e")
		m[1][3].should eq PlainText.new("f")
		m[2]?.should be_nil
		expect_raises(IndexError) do
			m[2]
		end
	end
end

describe Bold do
	it "contains PlainText if created with single String argument" do
		m = bold("some text")
		m.should be_a Bold
		m.children.size.should eq 1
		m.children[0].should be_a PlainText
		m.children[0].text.should eq "some text"
	end
	it "contains all arguments it was created with" do
		m = bold("some", italic("text"))
		m.should be_a Bold
		m.children.size.should eq 2
		m.children[0].should be_a PlainText
		m.children[0].text.should eq "some"
		m.children[1].should be_a Italic
		m.children[1].text.should eq "text"
	end
	describe "#to_s" do
		it "prints \\bold(...)" do
			m = bold("text")
			m.to_s.should eq "\\bold{text}"
		end
	end
	describe "#to_html" do
		it "prints <b>...</b>" do
			m = bold("text")
			m.to_html.should eq "<b>text</b>"
		end
	end
end

describe Italic do
	describe "#to_html" do
		it "prints <i>...</i>" do
			m = italic("text")
			m.to_html.should eq "<i>text</i>"
		end
	end
end

describe Small do
	describe "#to_html" do
		it "prints <small>...</small>" do
			m = small("text")
			m.to_html.should eq "<small>text</small>"
		end
	end
end

describe Paragraph do
	describe "#to_html" do
		it "prints <p>...</p>" do
			m = paragraph("text")
			m.to_html.should eq "<p>text</p>"
		end
	end
	describe "#to_ansi" do
		it "prints paragraphs separated by blank lines" do
			m = markup(
				paragraph("This is the first paragraph."),
				paragraph("Second paragraph follows."),
				paragraph("This is the third and final paragraph."))
			m.to_ansi.should eq <<-EXPECTED
				This is the first paragraph.

				Second paragraph follows.

				This is the third and final paragraph.
				EXPECTED
		end
		it "separates paragraphs from text outside paragraphs" do
			m = markup(
				"This text is outside any paragraph.",
				paragraph("This is inside a paragraph."))
			m.to_ansi.should eq <<-EXPECTED
				This text is outside any paragraph.

				This is inside a paragraph.
				EXPECTED
		end
	end
end
