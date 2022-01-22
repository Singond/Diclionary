require "spec"

require "../src/ssjc.cr"
require "../src/term.cr"

include Diclionary
include Diclionary::Text
include Diclionary::Ujc

def text_entry(term, format) : TextEntry
	result = SSJC.search(term, format)
	result.entries.size.should eq 1
	entry = result.entries[0]
	entry.should be_a TextEntry
	entry.as TextEntry
end

def printed(entry : TextEntry) : String
	style = TerminalStyle.new
	style.list_marker_alignment = Alignment::Left
	style.line_width = 72
	style.justify = false

	output = String::Builder.new
	Colorize.enabled = false
	format entry.text, output, style
	output.to_s.chomp('\n')
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
end
