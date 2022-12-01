require "spec"

require "../src/languages"

include Diclionary

describe Language do
	describe "#from_code" do
		it "parses 'en' as English" do
			lang = Language.from_code("en")
			lang.should_not be_nil
			lang = lang.as(Language)
			lang.two_letter.should eq "en"
			lang.three_letter.should eq "eng"
		end
		it "parses 'cs' as Czech" do
			lang = Language.from_code("cs")
			lang.should_not be_nil
			lang = lang.as(Language)
			lang.two_letter.should eq "cs"
			lang.three_letter.should eq "ces"
		end
	end
end
