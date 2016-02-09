
module SWIPL
	class PrologFrame
		def initialize( frame_id )
			@frame_id = frame_id
		end

		def close
			result = CFFI.PL_discard_foreign_frame( @frame_id )
			if result == PL_FALSE
				raise "Failed to close frame"
			end
		end

		# Opens a foreign frame
		def self.open
			frame_id = CFFI.PL_open_foreign_frame
			if frame_id == PL_FALSE 
				raise "failed to open frame"
			end
			PrologFrame.new( frame_id )
		end

		def self.on( &block )
			frame = self.open
			begin
				block.call( frame )
			ensure
				frame.close
			end
		end

		# allocates teh number of terms and returns an array of those terms
		#
		# NOTE: SWI requires continous terms from time to time (ie: PL_open_query) 
		def refs( count )
			return [] if count == 0

			base = CFFI.PL_new_term_refs( count )
			#TODO: Verify the result of the query
			(0..(count-1)).map do |index|
				Term.new( base + index )
			end
		end

		def ref
			refs(1)[0]
		end

		def atom_from_string( string )
			atom_ptr = FFI::MemoryPointer.from_string( string.to_s )
			atom_term = CFFI.PL_new_term_ref
			if CFFI.PL_chars_to_term( atom_ptr, atom_term ) == 0
				raise "failed to create atom from terms"
			end
			Term.new( atom_term )
		end
	end
end
