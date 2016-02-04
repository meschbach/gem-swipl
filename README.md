# SWIPL

A Ruby Gem for binding to SWI Prolog. This uses Ruby's FFI gem for binding.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'swipl'
```

## Usage

Set `SWI_LIB` to the where you have the libswipl.{dylib,so,dll} file.  Unforunately I haven't figured out a better method for locating the library; open to ideas and pull requests to make this easier for client applications.

### Basic Usage

You can query if a statement is truthy by passing it as string as follows:
```ruby
SWIPL::verify('true')
```

This will boot up the engine and run the query the Prolog for the answer.  Your programs can be arbitrarily complex, however this will only result in true or false.

### Usage Level 2

Let's say you have the following prolog database in foods.pl: 

```prolog
food( beef ).
food( broccoli ).
food( potatoes ).

enjoys( mark, broccoli ).
```

You can they load the database (assuming in the same directory) an query for all solutions as follows:

```ruby
SWIPL::truth( "consult('foods.pl')" )
foods = SWIPL::query( "food", 1 )
```

The variable foods should now contain the follow (note: order of the elements may change):
```ruby
[ ["beef"], ["broccoli"], ["potatoes"] ]
```

### Advanced Usage

This is kind of a gnarly API right now.  My goal is to clean it up, but querying with bound variables is
possible right now.

```ruby
SWIPL::PrologFrame.on do |frame|
	human = frame.atom_from_string( "mark" )
	predicate = SWIPL::Predicate.find( "enjoys", 2 )
	query = predicate.query_normally_with( frame, [human, nil ] ) # nil will result in an unground variable
	begin
		query.each_solution do |solution|
			puts solution
		end
	ensure
		query.close # if you forget this there will probably be some strange statement about no foreign frame
	end
end
```

Resulting output:
```ruby
["mark", "broccoli"]
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/meschbach/gem-swipl.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

