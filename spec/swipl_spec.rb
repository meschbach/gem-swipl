require 'spec_helper'

describe SWIPL do
  it 'has a version number' do
    expect(SWIPL::VERSION).not_to be nil
  end

  it 'true when consulting predicate true' do
		expect(SWIPL::verify('true')).to be true
  end

  it 'false when consulting predicate true' do
		expect(SWIPL::verify('false')).to be false
  end

	it 'verifies compound query loading from file' do
		expect(SWIPL::verify("consult('spec/compound_predicates.pl'), loaded_custom, !, unload_file('spec/compound_predicates.pl')")).to be true
	end

	it 'verifies compound queries containing backtracking' do
		expect(SWIPL::verify("( B = a ; B = b ), B = b")).to be true
	end

	it 'able to query for loaded predicate' do
		expect(SWIPL::verify( "consult('spec/call.pl')" )).to be true
		expect(SWIPL::query( "ediable", 1 )).to eq( [["cornbread"], ["mushroom"]] )
		expect(SWIPL::verify( "unload_file('spec/call.pl')" )).to be true
	end

	it 'will provide all values' do
		SWIPL::truth( "consult('spec/foods.pl')" )
		expect(SWIPL::query( "food", 1 )).to eq( [["beef"], ["broccoli"], ["potatoes"]] )
		SWIPL::truth( "unload_file('spec/food.pl')" )
	end

	def likes_solutions
		solutions = []
		SWIPL::PrologFrame.on do |frame|
			human = frame.atom_from_string("mark")
			predicate = SWIPL::Predicate.find( "enjoys", 2 )
			query = predicate.query_normally_with( frame, [human, nil ] )
			begin
				query.each_solution do |solution|
					solutions.push( solution[1].as_atom )
				end
			ensure
				query.close
			end
		end
		solutions
	end

	it 'applies bound variables' do
		SWIPL::truth( "consult('spec/foods.pl')" )
		expect( likes_solutions ).to eq(["broccoli"])
		SWIPL::truth( "unload_file('spec/food.pl')" )
	end

	describe "Deterministics Predicates" do
		it 'succeeds with a single argument' do
			capture = nil
			SWIPL::deterministic "ruby_predicate_1", 1 do |args|
				capture = args
				true
			end
			expect( capture ).to be_nil
			SWIPL::truth( "ruby_predicate_1(example_atom)" )
			expect( capture ).to_not be_nil
		end

		it 'correctly passes atoms in' do
			capture = nil
			SWIPL::deterministic "ruby_predicate_atom_in", 1 do |args|
				capture = args[0].as_atom
				true
			end
			expect( capture ).to be_nil
			SWIPL::truth( "ruby_predicate_atom_in(toast)" )
			expect( capture ).to eq "toast"
		end

		it 'passes in multiple variables' do
			capture = nil
			SWIPL::deterministic "ruby_predicate_multi_in", 2 do |args|
				capture = args.map do |arg|
					arg.as_atom
				end
			end
			expect( capture ).to be_nil
			SWIPL::truth( "ruby_predicate_multi_in( one, two )" )
			expect( capture ).to eq ["one", "two"]
		end

		it 'fails when the predicate fails' do
			SWIPL::deterministic "ruby_predicate_false", 0 do |args|
				false
			end
			SWIPL::fallacy( "ruby_predicate_false" )
		end

	end

	describe "Nondeterminsitic predicates" do
		it "true when returning true on initial" do
			SWIPL::nondet "ruby_nondet_true", 0 do
				SWIPL::PL_TRUE
			end 
			expect( SWIPL::find_all( "ruby_nondet_true" ) ).to eq [[]]
		end
	
		it "nothing when returning false on initial" do
			SWIPL::nondet "ruby_nondet_false", 0 do SWIPL::PL_FALSE end
			expect( SWIPL::find_all( "ruby_nondet_false" ) ).to eq []
		end

		it "backtracks across all solutions" do
			inputs = ["cast","iron","chef"]
			result = nil
			SWIPL::nondet "ruby_nondet_retry", 1 do | control, arguments |
				if control.first_call?
					arguments[0].unify_atom_chars( inputs[0] )
					ptr = FFI::MemoryPointer.new( :int, 1 )
					ptr.write_array_of_int( [ 1 ] )
					result = SWIPL::CFFI.PL_retry_address( ptr )
				elsif control.pruning?
					puts "Pruning"
				elsif control.redo?
					resume = control.context
					index = resume[0].read_int
					if index >= inputs.length
						result = SWIPL::PL_FALSE
					else
						arguments[0].unify_atom_chars( inputs[index] )
						resume.write_array_of_int( [index + 1] )
						result = SWIPL::CFFI.PL_retry_address( resume )
					end
				else
					puts "Unknown state #{control.inspect}"
				end
				result
			end

			SWIPL::PrologFrame.on do |frame|
				term = frame.ref
				result = SWIPL::find_all( "ruby_nondet_retry", [term] ) do
					|solution| solution.map {|term| term.ground? ? term.as_atom : "<not ground>" }
				end
				expect( result ).to eq [ ["cast"], ["iron"], ["chef"] ]
			end
		end
	end

	describe "list construction" do
		it "can construct a list from a set of terms" do
			SWIPL::PrologFrame.on do |frame|
				ruby_terms = ["get","happy","lose","control"].map { |e| frame.atom_from_string( e ) }
				ruby_list = frame.list_from_terms( ruby_terms )
				SWIPL::verify("assert( 'PL_cons_list'([get,happy,lose,control]) )")
				cursor = SWIPL::Predicate.find( "PL_cons_list", 1 ).query_normally_with( frame, [ruby_list] )
				begin
					expect( cursor.next_solution? ).to be(true)
				ensure
					cursor.close
				end
			end
		end
	end
end

