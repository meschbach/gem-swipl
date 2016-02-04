
module SWIPL
	class Query
		def initialize( qid, terms )
			@query_id = qid
			@terms = terms
		end

		def next_solution?
			CFFI.PL_next_solution( @query_id ) == PL_TRUE 
		end

		def each_solution
			while next_solution?
				yield(@terms)
			end
		end

		def close
			CFFI.PL_close_query( @query_id )
		end
	end
end
