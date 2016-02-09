
module SWIPL
	class Predicate
		def initialize( id, arity )
			@pred_id = id
			@arity = arity
		end

		def self.find( name, arity )
			name_ptr = FFI::MemoryPointer.from_string( name.to_s )
			id = CFFI.PL_predicate( name_ptr, arity, nil )
			Predicate.new( id, arity )
		end

		# @param frame the frame to allocate the parameters
		def query_normally( frame )
			params = frame.refs( @arity )
			query_id = CFFI.PL_open_query( nil, PL_Q_NORMAL, @pred_id, params[0].id )
			Query.new( query_id, params )
		end

		def query_normally_with( frame, inputs )
			raise "insufficent parameters for arity" if inputs.length != @arity

			params = frame.refs( @arity )
			(0..(@arity-1)).each do |index|
				source = inputs[ index ]
				if source
					params[index].unify_with( inputs[index] )
				end
			end

			base_ref = params.length > 0 ? params[0].id : 0

			query_id = CFFI.PL_open_query( nil, PL_Q_NORMAL, @pred_id, base_ref )
			raise "Failed to allocate query #{query_id}" if query_id == 0
			Query.new( query_id, params )
		end
	end
end
