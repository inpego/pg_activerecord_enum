# PgEnum

Integration of PostgreSQL native enums with ActiveRecord enums.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pg_enum', github: 'inpego/pg_enum'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pg_enum

## Usage

Migration:

```ruby
class CreateFruits < ActiveRecord::Migration[5.1]
  def up
    PgEnum.define :fruit_type, %i[banana orange grape]
    create_table :fruits do |t|
      t.column :fruit_type, :fruit_type
      t.timestamps
    end
  end

  def down
    drop_table :fruits
    PgEnum.drop :fruit_type
  end
end
```

Model:

```ruby
class Fruit < ApplicationRecord
  pg_enum :fruit_type
end
```

```ruby
Fruit.banana.count # 0
banana = Fruit.banana.create
banana.banana? # true
banana.grape! #
banana.grape? # true
Fruit.grape.count # 1
```

In PostgreSQL DB:
```
# select * from fruits;
 id | fruit_type |         created_at         |         updated_at         
----+------------+----------------------------+----------------------------
  1 | grape      | 2018-02-18 16:25:44.068334 | 2018-02-18 16:25:44.070939
(1 row)

# \dT+ fruit_type;
                                         List of data types
 Schema |    Name    | Internal name | Size | Elements |  Owner   | Access privileges | Description 
--------+------------+---------------+------+----------+----------+-------------------+-------------
 public | fruit_type | fruit_type    | 4    | banana  +| postgres |                   | 
        |            |               |      | orange  +|          |                   | 
        |            |               |      | grape    |          |                   | 
(1 row)

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/inpego/pg_enum.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
