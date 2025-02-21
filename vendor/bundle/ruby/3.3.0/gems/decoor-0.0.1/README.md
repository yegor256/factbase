# True Object-Oriented Decorator

[![DevOps By Rultor.com](http://www.rultor.com/b/yegor256/decoor)](http://www.rultor.com/p/yegor256/decoor)
[![We recommend RubyMine](https://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![rake](https://github.com/yegor256/decoor/actions/workflows/rake.yml/badge.svg)](https://github.com/yegor256/decoor/actions/workflows/rake.yml)
[![PDD status](http://www.0pdd.com/svg?name=yegor256/decoor)](http://www.0pdd.com/p?name=yegor256/decoor)
[![Gem Version](https://badge.fury.io/rb/decoor.svg)](http://badge.fury.io/rb/decoor)
[![Test Coverage](https://img.shields.io/codecov/c/github/yegor256/decoor.svg)](https://codecov.io/github/yegor256/decoor?branch=master)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/github/yegor256/decoor/master/frames)
[![Hits-of-Code](https://hitsofcode.com/github/yegor256/decoor)](https://hitsofcode.com/view/github/yegor256/decoor)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/yegor256/decoor/blob/master/LICENSE.txt)

Let's say, you have an object that you want to decorate, thus
adding new attributes and methods to it. Here is how:

```ruby
require 'decoor'
s = ' Jeff Lebowski '
d = decoor(s, br: ' ') do
  def parts
    @origin.strip.split(@br)
  end
end
assert(d.parts == ['Jeff', 'Lebowski'])
```

You may also turn an existing class into a decorator:

```ruby
require 'decoor'
class MyString
  def initialize(s, br)
    @s = s
    @br = br
  end
  decoor(:s)
  def parts
    @origin.strip.split(@br)
  end
end
d = MyString.new('Jeff Lebowski')
assert(d.parts == ['Jeff', 'Lebowski'])
```

That's it.

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
