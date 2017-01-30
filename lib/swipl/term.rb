
module SWIPL
	class Term
		def initialize( term_id )
			@term_id = term_id
		end

		def id; self.term_id; end
		def term_id; @term_id; end

		def unify_with( other_term, control = nil )
			result = CFFI.PL_unify( @term_id, other_term.term_id ) != PL_FAIL
			control.failed if control and !result
			result
		end

		def unify_string( string )
			CFFI.PL_unify_string_chars( @term_id, string )
		end

		def unify_atom_chars( string )
			CFFI.PL_unify_atom_chars( @term_id, string )
		end

		def put_string( string )
			CFFI.PL_put_string_chars( @term_id, string )
		end

		def put_atom( string )
			raise "Failed to put atom" if CFFI.PL_put_atom_chars( @term_id, string ) == PL_FALSE
		end

		def ground?
			str_ptr = FFI::MemoryPointer.new( :pointer, 1 )
			CFFI.PL_is_ground( @term_id ) == PL_TRUE
		end

		def atom?
			CFFI.PL_is_atom( @term_id ) == PL_TRUE 
		end

		def matches_atom?( to_string )
			atom? and as_atom == to_string
		end

		PL_VARIABLE = 1
		PL_ATOM = 2
		PL_NIL = 7
		PL_BLOB = 8
		PL_STRING = 5
		PL_INTEGER = 3

		def term_type
			type_id = CFFI.PL_term_type( @term_id )
			case type_id
				when PL_VARIABLE
					:variable
				when PL_ATOM
					:atom
				when PL_NIL
					:nil
				when PL_BLOB
					:blob
				when PL_STRING
					:string
				when PL_INTEGER
					:integer
				else
					:unknown
			end
		end

		def as_atom
			raise "not na atom" unless atom?
			str_ptr = FFI::MemoryPointer.new( :pointer, 1 )
			if CFFI.PL_get_atom_chars( @term_id, str_ptr ) == PL_FALSE
				raise "failed to get term #{@term_id} as an atom (type: #{term_type})"
			end
			str_ptr.read_pointer.read_string
		end

		def to_s
			if self.ground?
				if self.atom?
					self.as_atom
				else
					"ground (#{term_type})"
				end
			else
				"variable"
			end
		end

		def to_i
			@term_id
		end
	end
end
