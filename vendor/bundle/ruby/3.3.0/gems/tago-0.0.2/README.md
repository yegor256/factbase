# Adds `.ago()` Method to the `Time` Class

[![DevOps By Rultor.com](http://www.rultor.com/b/yegor256/tago)](http://www.rultor.com/p/yegor256/tago)
[![We recommend RubyMine](https://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![rake](https://github.com/yegor256/tago/actions/workflows/rake.yml/badge.svg)](https://github.com/yegor256/tago/actions/workflows/rake.yml)
[![PDD status](http://www.0pdd.com/svg?name=yegor256/tago)](http://www.0pdd.com/p?name=yegor256/tago)
[![Gem Version](https://badge.fury.io/rb/tago.svg)](http://badge.fury.io/rb/tago)
[![Test Coverage](https://img.shields.io/codecov/c/github/yegor256/tago.svg)](https://codecov.io/github/yegor256/tago?branch=master)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/github/yegor256/tago/master/frames)
[![Hits-of-Code](https://hitsofcode.com/github/yegor256/tago)](https://hitsofcode.com/view/github/yegor256/tago)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/yegor256/tago/blob/master/LICENSE.txt)

Here is how you use it:

```ruby
start = Time.now
# something long
puts "It took #{start.ago} to do it"
```

## How to contribute

Read
[these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).
Make sure you build is green before you contribute
your pull request. You will need to have
[Ruby](https://www.ruby-lang.org/en/) 3.2+ and
[Bundler](https://bundler.io/) installed. Then:

```bash
bundle update
bundle exec rake
```

If it's clean and you don't see any error messages, submit your pull request.
