require "spec"

require "../src/markup.cr"
require "../src/ssjc.cr"
require "../src/term.cr"

include Diclionary
include Diclionary::Text
include Diclionary::Ujc

style = TerminalStyle.new
style.list_marker_alignment = Alignment::Left
style.line_width = 72
style.justify = false

def text_entry(term, format) : TextEntry
	results = SSJC.search(term, format)
	results.size.should eq 1
	entry = results[0].entry
	entry.should be_a TextEntry
	entry.as TextEntry
end

def printed(entry : TextEntry) : String
	output = String::Builder.new
	Colorize.enabled = false
	format entry.text, output, style
	output.to_s.chomp('\n')
end

def parse_file(filename, format : Format) : Array(Entry)
	raw = File.read(filename)
	html = XML.parse_html(raw)
	SSJC.parse_response(html, format)
end

def parse_file_rich(filename) : Array(TextEntry)
	entries = parse_file(filename, Format::RichText)
	entries.map(&.as(TextEntry))
end

describe SsjcDictionary do
	it "parses '11.' as the eleventh item in a list, not first" do
		entries = parse_file_rich("spec/ssjc_longlist.html")
		entry = entries[0]
		entry.text[0].should be_a OrderedList
		ol = entry.text[0]
		ol.size.should eq 11
		ol[9].should be_a Item
		ol[9].text.strip.should eq "desátý význam"
		ol[10].should be_a Item
		ol[10].text.strip.should eq "jedenáctý význam"
	end
end

describe SsjcDictionary, tags: "online" do
	it do
		text = text_entry("hnidopich", Format::RichText).text
		list = text.find {|e, start| e.is_a? OrderedList}
		if !list
			fail "Parsed entry does not contain an ordered list"
		else
			list[0][0].text.chomp(' ').should eq "expr. kdo si všímá jen maličkostí, \
				malicherností, omezený puntičkář; hnidař: kancelářský, literární h."
			list[0][1].text.should start_with "žert. krejčí"
		end
	end
	it "can parse ordered list whose first item marker is prefixed" do
		text = text_entry("jeviti", Format::RichText).text
		list = text.find {|e, start| e.is_a? OrderedList}
		if !list
			fail "Parsed entry does not contain an ordered list"
		else
			list[0].size.should eq 4
		end
	end
end
