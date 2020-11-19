# Bookstack::Cli

A personal gem to create nice markdown exports of BookStack books and chapters.
It uses the (at-this-time) fairly new export API available since version 29.0
for books and 30.0 for chapters.

## Installation

Clone the repo then add this line to your application's Gemfile:

```ruby
gem 'bookstack-cli', path: 'path/to/repo'
```

This gem is unpublished, so you **must** set the path to the code.

And then execute:

    $ bundle install

## Usage

Environment variables `BOOKSTACK_TOKEN_ID` and `BOOKSTACK_TOKEN_SECRET` need to
be set when invoking `bookstack-cli`.

e.g.

`BOOKSTACK_TOKEN_ID=abc BOOKSTACK_TOKEN_SECRET=xyz bundle exec bookstack-cli books`

All commands:

```
Commands:
  bookstack-cli books                     # List all books
  bookstack-cli chapters                  # List all chapters
  bookstack-cli export RESOURCE SLUG      # Export BookStack book or chapter
  bookstack-cli help [COMMAND]            # Describe available commands or one specific command
  bookstack-cli raw_export RESOURCE SLUG  # Export book or chapter directly from BookStack
```

## Examples

_Note: For clarity, these are shown without the environment variables set or the
bundle exec included._

Use the `raw_export` subcommand to get the original single-file export from the
BookStack api. Mostly useful for debugging.

```
bookstack-cli raw_export --type=pdf       chapter my-chapter-slug
bookstack-cli raw_export --type=plaintext chapter my-chapter-slug
```

Use the `--output_file` flag to choose where to save the file.

```
bookstack-cli raw_export --type=html --output_file=/tmp/my.html chapter my-chapter-slug
```

Use the `export` subcommand to get the fancy export which extracts images into
their own files and does other cleanup.

```
bookstack-cli export chapter my-chapter-slug
bookstack-cli export --output_file=README.md chapter my-chapter-slug
```

There's a `--dryrun` flag to see the potential changes without actually changing
anything on the filesystem.

```
bookstack-cli export --dryrun chapter my-chapter-slug
```

There's also an `--html` flag which saves the transformed html file instead of
turning it into markdown. Mostly for debugging.

```
bookstack-cli export --html chapter my-chapter-slug
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/boatrite/bookstack-cli. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/boatrite/bookstack-cli/blob/main/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Bookstack::Cli project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/boatrite/bookstack-cli/blob/master/CODE_OF_CONDUCT.md).
