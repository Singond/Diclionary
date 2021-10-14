require "./core.cr"

module Diclionary
	struct Language
		English = Language.new("en", "eng")
		Czech = Language.new("cs", "ces")

		All = [English, Czech]

		def self.from_code(code : String) : Language?
			All.find(&.matches_code code)
		end
	end
end
