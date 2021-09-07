require "spec"

require "../src/markup.cr"

include Diclionary::Markup

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
		markup("x").to_a.should eq [PlainText.new("x")]
		m = markup(markup("x"), "y")
		m.to_a.should eq [m, PlainText.new("x"), PlainText.new("y")]
		m = markup("a", markup("b", "c", markup("d", "e"), "f"))
		m.to_a.should eq [m,
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
	it "supports other Enumerable methods" do
		m = markup("a", markup("b", "c", markup("d"), "e"))
		arr = [] of Markup
		m.each_with_object(arr) do |e, a|
			a << e
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
		markup("x").each.to_a.should eq [PlainText.new("x")]
		m = markup(markup("x"), "y")
		m.each.to_a.should eq [m, PlainText.new("x"), PlainText.new("y")]
		m = markup("a", markup("b", "c", markup("d", "e"), "f"))
		m.each.to_a.should eq [m,
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
end

describe MarkupVisitor do
	describe "#visit" do
		it "does not fail when not initialized" do
			m = markup("a", bold("b"), "c")
			v = MarkupVisitor.new
			v.visit(m)
		end
		it "allows walking the markup tree in proper order" do
			m = markup("a", bold("b"), "c")
			v = MarkupVisitor.new
			arr = [] of Markup
			v.open do |e|
				arr << e
			end
			v.visit(m)
			arr.should eq [m, markup("a"), bold("b"), markup("b"), markup("c")]
		end
		# it "allows executing custom code on entering and leaving elements" do
		#
		# end
		it "allows extracting the text content" do
			m = markup("a", bold("b"), "c")
			v = MarkupVisitor.new
			str = ""
			v.open do |e|
				case e
				when PlainText
					str += e.text
				end
			end
			v.visit(m)
			str.should eq "abc"
		end
		it "allows rewriting the tree into another representation" do
			m = markup("a ", bold("bold and also ", italic("italic")), " text")
			v = MarkupVisitor.new
			str = ""
			v.open do |e|
				case e
				when PlainText
					str += e.text
				when Bold
					str += %q(\textbf{)
				when Italic
					str += %q(\textit{)
				end
			end
			v.close do |e|
				case e
				when Bold, Italic
					str += '}'
				end
			end
			v.visit(m)
			str.should eq %q(a \textbf{bold and also \textit{italic}} text)
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
end
