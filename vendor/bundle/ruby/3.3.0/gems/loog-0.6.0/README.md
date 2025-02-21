# Object-Oriented Logger for Ruby

[![EO principles respected here](https://www.elegantobjects.org/badge.svg)](https://www.elegantobjects.org)
[![DevOps By Rultor.com](http://www.rultor.com/b/yegor256/loog)](http://www.rultor.com/p/yegor256/loog)
[![We recommend RubyMine](https://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![rake](https://github.com/yegor256/loog/actions/workflows/rake.yml/badge.svg)](https://github.com/yegor256/loog/actions/workflows/rake.yml)
[![Gem Version](https://badge.fury.io/rb/loog.svg)](http://badge.fury.io/rb/loog)
[![Maintainability](https://api.codeclimate.com/v1/badges/4346229c7af42b820e84/maintainability)](https://codeclimate.com/github/yegor256/loog/maintainability)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/github/yegor256/loog/master/frames)
[![Test Coverage](https://img.shields.io/codecov/c/github/yegor256/loog.svg)](https://codecov.io/github/yegor256/loog?branch=master)
[![Hits-of-Code](https://hitsofcode.com/github/yegor256/loog)](https://hitsofcode.com/view/github/yegor256/loog)

Loog is an object-oriented logging wrapper around Ruby
[`Logger`](https://ruby-doc.org/stdlib-2.4.0/libdoc/logger/rdoc/Logger.html).

First, install it:

```bash
gem install loog
```

Then, use it like this:

```ruby
require 'loog'
Loog::VERBOSE.info('Hello, world!')
```

The gem is basically a provider of a few pre-configured loggers, which
you can use for production (`Loog::REGULAR`) or for testing (`Loog::VERBOSE`).
You can also shut it up with `Loog::NULL`.

There is also `Loog::Buffer` class that you can use for testing.
It accumulates all log calls and then returns the entire output
through the `to_s()` method.

## How to contribute

Read
[these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).
Make sure you build is green before you contribute
your pull request. You will need to have
[Ruby](https://www.ruby-lang.org/en/) 2.3+ and
[Bundler](https://bundler.io/) installed. Then:

```bash
bundle update
bundle exec rake
```

If it's clean and you don't see any error messages, submit your pull request.
