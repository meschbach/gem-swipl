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
end
