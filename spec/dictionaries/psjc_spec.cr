require "spec"

require "../../src/markup"
require "../../src/term"
require "../../src/dictionaries/psjc"

include Diclionary
include Diclionary::Text
include Diclionary::Ujc

style = TerminalStyle.new
style.list_marker_alignment = Alignment::Left
style.line_width = 72
style.justify = false

def text_entry_psjc(term, format) : TextEntry
	results = PSJC.search(term, format)
	results.size.should eq 1
	entry = results[0].entry
	entry.should be_a TextEntry
	entry.as TextEntry
end

describe PsjcDictionary, tags: "online" do
	it "parses multiple senses as list" do
		text = text_entry_psjc("krystal", Format::RichText).text
		lists = text.find {|e, start| e.is_a? UnorderedList}
		if !lists
			fail "Parsed entry contains no unordered list"
		end
		list = lists[0]
		# In reality, this entry contains 4 senses, but the first
		# one is hard to distinguish from the generic description
		# preceding it. Currently, the first sense is merged into
		# the first paragraph, leaving only the other three senses
		# in the list.
		list.children.size.should eq 3
		list.children.[0].text.should start_with "krystalový detektor"
		list.children.[1].text.should start_with "Zbož. krystalový cukr"
		list.children.[2].text.should start_with "křišťál"
	end
end
