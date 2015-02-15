# Sketch-Chest

The lightweight plugin manager for Sketch.app.

## Installation

```console
$ gem install chest
```

## Usage

You can install Sketch plugins from Github by using `install` command:

```console
$ chest install https://github.com/uetchy/Sketch-StickyGrid.git
```

Also you can use `uninstall`, `update`, `list` commands like this:

```console
$ chest uninstall Sketch-StickyGrid # delete from Plugins folder
$ chest update Sketch-StickyGrid    # pull from git
$ chest update                      # this updates all of plugins
$ chest list                        # list installed plugins
```

To see all of available commands, use `help` command:

```console
$ chest help
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec chest` to use the code located in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/uetchy/Sketch-Chest/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
