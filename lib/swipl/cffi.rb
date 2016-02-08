require 'ffi'

module SWIPL
	module CFFI
		extend FFI::Library
		typedef :pointer, :foreign_t

		def self.import_symbols
			attach_function :PL_open_foreign_frame, [], :ulong
			attach_function :PL_discard_foreign_frame, [:ulong], :int

			# Warning: the following method repeatedly failed
			attach_function :PL_atom_chars, [:ulong], :pointer

			attach_function :PL_call, [:ulong, :pointer], :int
			attach_function :PL_chars_to_term, [:pointer, :ulong], :int
			attach_function :PL_close_query, [:ulong], :void
			attach_function :PL_get_atom_chars, [:ulong, :pointer], :int
			attach_function :PL_initialise, [:int, :pointer], :int
			attach_function :PL_is_atom, [:ulong], :int
			attach_function :PL_is_ground, [:ulong], :int
			attach_function :PL_new_atom, [:pointer], :ulong
			attach_function :PL_new_term_ref, [], :ulong
			attach_function :PL_new_term_refs, [:int], :ulong
			attach_function :PL_next_solution, [:ulong], :int
			attach_function :PL_open_query, [:pointer, :int, :ulong, :ulong], :ulong
			attach_function :PL_predicate, [:pointer, :int, :pointer], :ulong
			attach_function :PL_register_foreign, [:pointer, :int, :pointer, :int], :foreign_t
			attach_function :PL_thread_self, [], :int
			attach_function :PL_unify, [ :ulong, :ulong ], :int
		end

		def self.PL_succeed; PL_TRUE; end

		def self.load( libraries )
			ffi_lib libraries
			self.import_symbols
		end

		def self.bootstrap
			lib_path = ENV["SWI_LIB"]
			raise "SWI_LIB not set and loader for your platform." unless lib_path

			@swipl_lib = lib_path
			self.load( lib_path )
		end

		def self.init
			return if @is_initialized
			self.bootstrap unless @ffi_libs

			libptr = ::FFI::MemoryPointer.from_string( @swipl_lib )
			plargv = ::FFI::MemoryPointer.new( :pointer, 1 )
			plargv.write_pointer( libptr )

			value = PL_initialise( 1, plargv )
			if value != 1
				raise "SWI failed to initialize"
			end

			@is_initialized = true
		end
	end
end
