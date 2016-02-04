require "swipl/ffi"
require 'swipl/predicate'
require 'swipl/prologframe'
require 'swipl/query'
require 'swipl/term'
require "swipl/version"

module SWIPL
	PL_TRUE = 1
	PL_FALSE = 2
	PL_FAIL = PL_FALSE
	PL_Q_NORMAL = 2

	def self.verify( fact )
		FFI.init
		PrologFrame.on do |frame|
			atom = frame.atom_from_string( fact )
			FFI.PL_call( atom.term_id, nil ) == PL_TRUE
		end
	end

	def self.query( predicateName, arity )
		solutions = []
		PrologFrame.on do |frame|
			predicate = Predicate.find( predicateName, arity)
			query = predicate.query_normally( frame )
			begin
				query.each_solution do |p|
					solutions.push([ p[0].as_atom ] )
				end
			ensure
				query.close
			end
		end
		solutions
	end
end
