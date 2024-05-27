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
It is possible to delete a fact, but impossible to delete a property
from a fact.

**ATTENTION**: The current implemention is naive and,
because of that, very slow. I will be very happy
if you suggest a better implementation without the change of the interface.
The `Factbase::query()` method is what mostly needs performance optimization:
currently it simply iterates through all facts in the factbase in order
to find those that match the provided terms. Obviously,
even a simple indexing may significantly increase performance.

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

There are some terms available in a query:

* `(always)` and `(never)` are "true" and "false"
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
* `(many a)` return true if there are many values in the `a` property
* `(one a)` returns true if there is only one value in the `a` property
* `(at i a)` returns the `i`-th value of the `a` property
* `(either a b)` returns `b` if `a` is `nil`
* `(matches a re)` returns true when `a` matches regular expression `re`
* `(defn foo "self.to_s")` defines a new term using Ruby syntax and returns true

Also, some simple arithmetic:

* `(plus a b)` is a sum of `a` and `b`
* `(minus a b)` is a deducation of `b` from `a`
* `(times a b)` is a multiplication of `a` and `b`
* `(div a b)` is a division of `a` by `b`

There are terms that are history of search aware:

* `(prev a)` returns the value of `a` in the previously seen fact

There are also terms that match the entire factbase
and must be used inside the `(agg ..)` term:

* `(count)` returns the tally of facts
* `(max k)` returns the maximum value of the `k` property in all facts
* `(min k)` returns the minimum
* `(sum k)` returns the arithmetic sum of all values of the `k` property

The `agg` term enables sub-queries by evaluating the first argument (term)
over all available facts, passing the entire subset to the second argument,
and then returning the result as an atomic value:

* `(lt age (agg (eq gender 'F') (max age)))` selects all facts where
the `age` is smaller than the maximum `age` of all women
* `(eq id (agg (always) (max id)))` selects the fact with the largest `id`

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
