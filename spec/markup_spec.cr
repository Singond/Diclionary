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
end

describe Markup do
	it "can be nested" do
		m = markup("a", markup("b", "c", markup("d"), "e"))
		m.children[0].should eq markup("a")
		m.children[1].should eq markup("b", "c", markup("d"), "e")
		m.children[1].children[0].should eq markup("b")
		m.children[1].children[1].should eq markup("c")
		m.children[1].children[2].should eq markup("d")
		m.children[1].children[3].should eq markup("e")
	end
end
