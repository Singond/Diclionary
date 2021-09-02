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
		m.children[0].should eq markup("a")
		m.children[1].should eq markup("b", "c", markup("d"), "e")
		m.children[1].children[0].should eq markup("b")
		m.children[1].children[1].should eq markup("c")
		m.children[1].children[2].should eq markup("d")
		m.children[1].children[3].should eq markup("e")
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
end
