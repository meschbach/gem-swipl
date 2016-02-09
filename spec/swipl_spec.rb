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
			SWIPL::ruby_predicate "ruby_predicate_1", 1 do |args|
				capture = args
				true
			end
			expect( capture ).to be_nil
			SWIPL::truth( "ruby_predicate_1(example_atom)" )
			expect( capture ).to_not be_nil
		end

		it 'correctly passes atoms in' do
			capture = nil
			SWIPL::ruby_predicate "ruby_predicate_atom_in", 1 do |args|
				capture = args[0].as_atom
				true
			end
			expect( capture ).to be_nil
			SWIPL::truth( "ruby_predicate_atom_in(toast)" )
			expect( capture ).to eq "toast"
		end

		it 'passes in multiple variables' do
			capture = nil
			SWIPL::ruby_predicate "ruby_predicate_multi_in", 2 do |args|
				capture = args.map do |arg|
					arg.as_atom
				end
			end
			expect( capture ).to be_nil
			SWIPL::truth( "ruby_predicate_multi_in( one, two )" )
			expect( capture ).to eq ["one", "two"]
		end

		it 'fails when the predicate fails' do
			SWIPL::ruby_predicate "ruby_predicate_false", 0 do |args|
				false
			end
			SWIPL::fallacy( "ruby_predicate_false" )
		end

	end

	describe "Nondeterminsitic predicates" do
		it "true when returning true" do
			SWIPL::nondet "ruby_nondet_true", 0 do
				true
			end

			solutions = []
			SWIPL::PrologFrame.on do |frame|
				predicate = SWIPL::Predicate.find( "ruby_nondet_true", 0 )
				query = predicate.query_normally_with( frame, [] )
				begin
					query.each_solution do |solution|
						solutions.push( solution )
					end
				ensure
					query.close
				end
			end
			expect( solutions ).to eq [[]]
		end
	end
end

