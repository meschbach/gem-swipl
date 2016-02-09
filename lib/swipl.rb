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
	PL_FA_NONDETERMINISTIC = 4

	PL_FIRST_CALL = 0
	PL_PRUNED = 1
	PL_REDO = 2

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

	def self.deterministic( name, arity, &block )
		CFFI.init
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

	class ForeignControl
		def initialize( state )
			@state = state
		end

		def context; @context ; end
		def context=( value ); @context = value ; end
		def first_call?; @state == PL_FIRST_CALL; end
		def pruning?; @state == PL_PRUNED; end
		def redo?; @state == PL_REDO; end
	end

	class ForeignFrame
	end

	def self.nondet( name, arity, &handler )
		CFFI.init

		@registered = {} unless @registered
		raise "predicate by that name is already registered" if @registered[ name ]

		trampoline = CFFI::predicate_proc do |arg_base, arity, control|
			result = nil

			arguments = (0..(arity -1 )).map do |index|
				Term.new( arg_base + index )
			end

			stage = ForeignControl.new CFFI.PL_foreign_control( control )
			stage.context = CFFI.PL_foreign_context_address( control ) unless stage.first_call?
			frame = ForeignFrame.new
			handler.call( stage , arguments, frame, control )
		end
		@registered[name] = trampoline

		name_ptr = FFI::MemoryPointer.from_string( name.to_s )
		raise "Failed to register" unless CFFI.PL_register_foreign( name_ptr, arity, trampoline, PL_FA_VARARGS | PL_FA_NONDETERMINISTIC )
	end

	#
	#
	def self.find_all( name, args = [], &solution_handler )
		solution_handler = Proc.new { |s| s } unless solution_handler
		solutions = []
		SWIPL::PrologFrame.on do |frame|
			predicate = SWIPL::Predicate.find( name, args.length )
			query = predicate.query_normally_with( frame, args )
			begin
				query.each_solution do |solution|
					solutions.push( solution_handler.call(solution) )
				end
			ensure
				query.close
			end
		end
		solutions
	end
end

