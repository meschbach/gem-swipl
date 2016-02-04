require 'swipl/ffi'

module SWIPL
	class Term
		def initialize( term_id )
			@term_id = term_id
		end

		def id; self.term_id; end
		def term_id; @term_id; end

		def unify_with( other_term )
			SWIPL::FFI.PL_unify( @term_id, other_term.term_id ) != PL_FAIL
		end

		def ground?
			SWIPL::FFI.PL_is_ground( @term_id ) == PL_TRUE
		end

		def atom?
			SWIPL::FFI.PL_is_atom( @term_id ) 
		end

		def as_atom
			str_ptr = ::FFI::MemoryPointer.new( :pointer, 1 )
			if SWIPL::FFI.PL_get_atom_chars( @term_id, str_ptr ) == PL_FALSE
				raise "failed to get term #{@term_id} as an atom"
			end
			str_ptr.read_pointer.read_string
		end

		def to_s
			if self.ground?
				if self.atom?
					self.as_atom
				else
					"ground"
				end
			else
				"variable"
			end
		end
	end
end
