<img src="/logo.svg" width="64px" height="64px"/>

[![DevOps By Rultor.com](http://www.rultor.com/b/yegor256/backtrace)](http://www.rultor.com/p/yegor256/backtrace)
[![We recommend RubyMine](https://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![rake](https://github.com/yegor256/backtrace/actions/workflows/rake.yml/badge.svg)](https://github.com/yegor256/backtrace/actions/workflows/rake.yml)
[![Gem Version](https://badge.fury.io/rb/backtrace.svg)](http://badge.fury.io/rb/backtrace)
[![Maintainability](https://api.codeclimate.com/v1/badges/0296baf81e86b90fba70/maintainability)](https://codeclimate.com/github/yegor256/backtrace/maintainability)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/github/yegor256/backtrace/master/frames)
[![Hits-of-Code](https://hitsofcode.com/github/yegor256/backtrace)](https://hitsofcode.com/view/github/yegor256/backtrace)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/yegor256/backtrace/blob/master/LICENSE.txt)

A Ruby backtrace nicely printed.

First, install it:

```bash
$ gem install backtrace
```

Then, use it like this, to print a backtrace:

```ruby
require 'backtrace'
begin
  # do something dangerous
rescue StandardError => e
  puts Backtrace.new(e)
end
```

![screenshot](https://raw.githubusercontent.com/yegor256/backtrace/master/screenshot.png)

A more compact version would use a block:

```ruby
require 'backtrace'
Backtrace.exec(swallow: true) do
  # do something dangerous
end
```

You can also provide a logging facility, to log the backtrace:

```ruby
require 'backtrace'
log = Log.new # it must implement method error(msg)
Backtrace.exec(swallow: true, log: log) do
  # do something dangerous
end
```

Sometimes you may need to hide unimportant lines of the backtrace,
which are not related to your code base. You can use `mine` argument
of the constructor, which is a regular expression or a string. When it's met
in the backtrace, the printing will stop:

```ruby
require 'backtrace'
begin
  # do something dangerous
rescue StandardError => e
  puts Backtrace.new(e, mine: 'yegor')
end
```

That's it.

## How to contribute

Read [these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).
Make sure you build is green before you contribute
your pull request. You will need to have [Ruby](https://www.ruby-lang.org/en/) 2.3+ and
[Bundler](https://bundler.io/) installed. Then:

```
$ bundle update
$ bundle exec rake
```

If it's clean and you don't see any error messages, submit your pull request.
