require "spec"

include Diclionary

# Use mocked dictionaries in tests.
# The following redefines the `init_dictionaries` method to return a custom
# array of dictionaries.
# The array must be set beforehand by calling `dictionaries = [dicts]`.
#
# In order for this to work, this file must be imported *after* `main.cr`.

module Diclionary
	Dicts = [] of Dictionary

	def init_dictionaries(config : Config) : Array(Dictionary)
		Dicts
	end

	def dictionaries=(dicts)
		Dicts.clear
		dicts.each do |d|
			Dicts << d
		end
	end
end
