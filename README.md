![Logo](https://raw.githubusercontent.com/Sketch-Chest/chest/master/assets/readme_images/logo.png)

# Chest

[![Build Status](https://travis-ci.org/Sketch-Chest/chest.svg?branch=master)](https://travis-ci.org/Sketch-Chest/chest) [![Join the chat at https://gitter.im/Sketch-Chest/chest](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/Sketch-Chest/chest?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

The lightweight plugin manager for Sketch.

This software requires OS X Mavericks or later.

## Install

```console
$ gem install chest
```

## Usage

You can install Sketch plugins which is hosted on GitHub by using `install` command:

```console
$ chest install uetchy/Sketch-StickyGrid
```

Or just specify Git url:

```console
$ chest install https://github.com/uetchy/Sketch-StickyGrid.git
```

Also you can use `uninstall`, `update`, `list`, et al.:

```console
$ chest uninstall StickyGrid # delete from Plugins folder
$ chest update StickyGrid    # pull from git
$ chest update               # update all plugins
$ chest list                 # list installed plugins
$ chest info                 # show plugin information
$ chest init                 # generate manifest.json for your plugin
$ chest open                 # open plugin folder in Finder
```

To see all of available commands, use `help` command:

```console
$ chest help
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec chest` to use the code located in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Issues are welcome!

1. Fork it ( <https://github.com/Sketch-Chest/chest/fork> )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
