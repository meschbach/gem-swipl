require "swipl/ffi"
require 'swipl/prologframe'
require 'swipl/term'
require "swipl/version"

module SWIPL
	PL_TRUE = 1
	PL_FALSE = 2
	PL_FAIL = PL_FALSE
	PL_Q_NORMAL = 2

	def self.verify( fact )
		SWIPL::FFI.init
		PrologFrame.on do |frame|
			atom = frame.atom_from_string( fact )
			SWIPL::FFI.PL_call( atom.term_id, nil ) == PL_TRUE
		end
	end
end
