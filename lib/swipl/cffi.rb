require 'ffi'

module SWIPL
	module CFFI
		extend FFI::Library
		typedef :pointer, :foreign_t
		typedef :pointer, :control_t
		typedef :ulong, :term_t

		class PL_thread_attr_t < FFI::Struct
			layout	:local_size,	:ulong,
				:global_size,	:ulong,
				:trail_size,	:ulong,
				:argument_size, :ulong,
				:alias_name,	:pointer,
				:cancel,	:pointer,
				:flags,		:pointer
		end

		def self.import_symbols
			attach_function :PL_open_foreign_frame, [], :ulong
			attach_function :PL_discard_foreign_frame, [:ulong], :int

			# Warning: the following method repeatedly failed
			attach_function :PL_atom_chars, [:ulong], :pointer

			attach_function :PL_call, [:ulong, :pointer], :int
			attach_function :PL_chars_to_term, [:pointer, :ulong], :int
			attach_function :PL_close_query, [:ulong], :void
			attach_function :PL_foreign_control, [:control_t], :int
			attach_function :PL_foreign_context_address, [:control_t], :pointer
			attach_function :long_PL_foreign_context_address, :PL_foreign_context_address, [:control_t], :ulong
			attach_function :PL_get_atom_chars, [:ulong, :pointer], :int
			attach_function :PL_initialise, [:int, :pointer], :int
			attach_function :PL_is_atom, [:term_t], :int
			attach_function :PL_is_ground, [:term_t], :int
			attach_function :PL_new_atom, [:pointer], :ulong
			attach_function :PL_new_term_ref, [], :term_t
			attach_function :PL_new_term_refs, [:int], :term_t
			attach_function :PL_next_solution, [:ulong], :int
			attach_function :PL_open_query, [:pointer, :int, :ulong, :term_t], :ulong
			attach_function :PL_put_atom_chars, [ :term_t, :string], :int
			attach_function :PL_put_string_chars, [ :term_t, :string], :void
			attach_function :PL_predicate, [:pointer, :int, :pointer], :ulong
			attach_function :PL_register_foreign, [:pointer, :int, :pointer, :int], :foreign_t
			attach_function :_PL_retry_address, [ :pointer ], :foreign_t
			attach_function :_PL_retry, [ :pointer ], :foreign_t
			attach_function :PL_term_type, [:term_t], :int
			attach_function :PL_thread_self, [], :int
			attach_function :PL_unify, [ :term_t, :term_t ], :int
			attach_function :PL_unify_string_chars, [ :ulong, :string], :void
			attach_function :PL_unify_atom_chars, [ :term_t, :string], :void

			# 1 thread : 1 prolog engine pool
			# http://www.swi-prolog.org/pldoc/man?section=foreignthread
			attach_function :PL_thread_self, [], :int
			attach_function :PL_thread_attach_engine, [:pointer], :int
			attach_function :PL_thread_destroy_engine, [], :int
		end

		def self.PL_succeed; PL_TRUE; end
		def self.PL_retry_address( what ); _PL_retry_address( what ).address; end
		def self.PL_retry( ptr ); _PL_retry( ptr ).address; end

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

			args = [ @swipl_lib ]

			plargv = ::FFI::MemoryPointer.new( :pointer, args.count + 1 )
			args.each do |arg|
				ptr = ::FFI::MemoryPointer.from_string( arg )
				plargv.write_pointer( ptr )
			end

			value = PL_initialise( args.count, plargv )
			if value != 1
				raise "SWI failed to initialize"
			end

			@is_initialized = true
		end

		def self.predicate_proc( &handler )
			FFI::Function.new( :size_t, [:ulong, :int, :pointer], handler )
		end
	end
end
