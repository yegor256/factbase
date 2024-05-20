# Single-Table NoSQL In-Memory Database

[![DevOps By Rultor.com](http://www.rultor.com/b/yegor256/factbase)](http://www.rultor.com/p/yegor256/factbase)
[![We recommend RubyMine](https://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![rake](https://github.com/yegor256/factbase/actions/workflows/rake.yml/badge.svg)](https://github.com/yegor256/factbase/actions/workflows/rake.yml)
[![PDD status](http://www.0pdd.com/svg?name=yegor256/factbase)](http://www.0pdd.com/p?name=yegor256/factbase)
[![Gem Version](https://badge.fury.io/rb/factbase.svg)](http://badge.fury.io/rb/factbase)
[![Test Coverage](https://img.shields.io/codecov/c/github/yegor256/factbase.svg)](https://codecov.io/github/yegor256/factbase?branch=master)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/github/yegor256/factbase/master/frames)
[![Hits-of-Code](https://hitsofcode.com/github/yegor256/factbase)](https://hitsofcode.com/view/github/yegor256/factbase)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/yegor256/factbase/blob/master/LICENSE.txt)

This Ruby gem manages an in-memory database of facts.
A fact is simply a map of properties and values.
The values are either atomic literals or non-empty sets of literals.
It is possible to delete a fact, but impossible to delete a property from a fact.

Here is how you use it (it's thread-safe, by the way):

```ruby
fb = Factbase.new
f = fb.insert
f.kind = 'book'
f.title = 'Object Thinking'
fb.query('(eq kind "book")').each do |f|
  f.seen = true
end
fb.insert
fb.query('(not (exists seen))').each do |f|
  f.title = 'Elegant Objects'
end
```

You can save the factbase to the disc and then load it back:

```ruby
file = '/tmp/simple.fb'
f1 = Factbase.new
f = f1.insert
f.foo = 42
File.save(file, f1.export)
f2 = Factbase.new
f2.import(File.read(file))
assert(f2.query('(eq foo 42)').each.to_a.size == 1)
```

All terms available in a query:

* `()` is true
* `(nil)` is false
* `(not t)` inverses the `t` if it's boolean (exception otherwise)
* `(or t1 t2 ...)` returns true if at least one argument is true
* `(and t1 t2 ...)` returns true if all arguments are true
* `(when t1 t2)` returns true if `t1` is true and `t2` is true or `t1` is false
* `(exists k)` returns true if `k` property exists in the fact
* `(absent k)` returns true if `k` property is absent
* `(eq a b)` returns true if `a` equals to `b`
* `(lt a b)` returns true if `a` is less than `b`
* `(gt a b)` returns true if `a` is greater than `b`
* `(size k)` returns cardinality of `k` property (zero if property is absent)
* `(type a)` returns type of `a` ("String", "Integer", "Float", or "Time")
* `(defn foo "self.to_s")` defines a new term using Ruby syntax and returns true

## How to contribute

Read [these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).
Make sure you build is green before you contribute
your pull request. You will need to have
[Ruby](https://www.ruby-lang.org/en/) 3.2+ and
[Bundler](https://bundler.io/) installed. Then:

```bash
bundle update
bundle exec rake
```

If it's clean and you don't see any error messages, submit your pull request.
