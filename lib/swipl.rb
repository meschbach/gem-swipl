require "swipl/cffi"
require 'swipl/predicate'
require 'swipl/prologframe'
require 'swipl/query'
require 'swipl/term'
require "swipl/version"

module SWIPL
	PL_FALSE = 0
	PL_TRUE = 1
	PL_FAIL = PL_FALSE
	PL_Q_NORMAL = 2
	PL_FA_VARARGS =  8

	def self.verify( fact )
		CFFI.init
		PrologFrame.on do |frame|
			atom = frame.atom_from_string( fact )
			CFFI.PL_call( atom.term_id, nil ) == PL_TRUE
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

	def self.truth( fact )
		unless self.verify( fact )
			raise "Truth '#{fact}' failed"
		end
	end

	def self.fallacy( fact )
		if self.verify( fact )
			raise "Fallacy '#{fact}' is true"
		end
	end

	def self.ruby_predicate( name, arity, &block )
		@registered = {} unless @registered
		raise "predicate by that name is already registered" if @registered[ name ]

		trampoline = FFI::Function.new( :uint, [:ulong, :int, :pointer] ) do |arg_base, arity, control|
			stage = CFFI.PL_foreign_control( control )

			arguments = (0..(arity -1 )).map do |index|
				Term.new( arg_base + index )
			end

			if block.call( arguments )
				CFFI::PL_succeed()
			else
				PL_FALSE
			end
		end

		name_ptr = FFI::MemoryPointer.from_string( name.to_s )
		raise "Failed to register" unless CFFI.PL_register_foreign( name_ptr, arity, trampoline, PL_FA_VARARGS )
	end

	def self.nondet( name, arity, &block )
		@registered = {} unless @registered
		raise "predicate by that name is already registered" if @registered[ name ]

		trampoline = FFI::Function.new( :uint, [:ulong, :int, :pointer] ) do |arg_base, arity, control|
			stage = CFFI.PL_foreign_control( control )

			arguments = (0..(arity -1 )).map do |index|
				Term.new( arg_base + index )
			end

			if block.call( arguments )
				CFFI::PL_succeed()
			else
				PL_FALSE
			end
		end

		name_ptr = FFI::MemoryPointer.from_string( name.to_s )
		raise "Failed to register" unless CFFI.PL_register_foreign( name_ptr, arity, trampoline, PL_FA_VARARGS )
	end
end

