# Single-Table NoSQL-ish In-Memory Database

[![DevOps By Rultor.com](https://www.rultor.com/b/yegor256/factbase)](https://www.rultor.com/p/yegor256/factbase)
[![We recommend RubyMine](https://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![rake](https://github.com/yegor256/factbase/actions/workflows/rake.yml/badge.svg)](https://github.com/yegor256/factbase/actions/workflows/rake.yml)
[![discipline](https://zerocracy.github.io/judges-action/zerocracy-badge.svg)](https://zerocracy.github.io/judges-action/zerocracy-vitals.html)
[![PDD status](https://www.0pdd.com/svg?name=yegor256/factbase)](https://www.0pdd.com/p?name=yegor256/factbase)
[![Gem Version](https://badge.fury.io/rb/factbase.svg)](https://badge.fury.io/rb/factbase)
[![Test Coverage](https://img.shields.io/codecov/c/github/yegor256/factbase.svg)](https://codecov.io/github/yegor256/factbase?branch=master)
[![Yard Docs](https://img.shields.io/badge/yard-docs-blue.svg)](https://rubydoc.info/github/yegor256/factbase/master/frames)
[![Hits-of-Code](https://hitsofcode.com/github/yegor256/factbase)](https://hitsofcode.com/view/github/yegor256/factbase)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/yegor256/factbase/blob/master/LICENSE.txt)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fyegor256%2Ffactbase.svg?type=shield&issueType=license)](https://app.fossa.com/projects/git%2Bgithub.com%2Fyegor256%2Ffactbase?ref=badge_shield&issueType=license)

This Ruby gem manages an in-memory database of facts.
A fact is simply an associative array of properties and their values.
The values are either atomic literals or non-empty sets of literals.
It is possible to delete a fact, but impossible to delete a property
from a fact.

Here is how you use it (it's thread-safe, by the way):

```ruby
fb = Factbase.new
f = fb.insert
f.kind = 'book'
f.title = 'Object Thinking'
fb.query('(eq kind "book")').each do |f|
  f.seen = Time.now
end
fb.insert
fb.query('(not (exists seen))').each do |f|
  f.title = 'Elegant Objects'
end
```

You can save the factbase to the disk and then load it back:

```ruby
file = '/tmp/simple.fb'
f1 = Factbase.new
f = f1.insert
f.foo = 42
File.binwrite(file, f1.export)
f2 = Factbase.new
f2.import(File.binread(file))
assert(f2.query('(eq foo 42)').each.to_a.size == 1)
```

You can check the presence of an attribute by name and then
set it, also by name:

```ruby
n = 'foo'
if f[n].nil?
  f.send("#{n}=", 'Hello, world!')
end
```

You can make a factbase log all operations:

```ruby
require 'loog'
require 'factbase/logged'
log = Loog::VERBOSE
fb = Factbase::Logged.new(Factbase.new, log)
f = fb.insert
```

You can also count the amount of changes made to a factbase:

```ruby
require 'loog'
require 'factbase/tallied'
log = Loog::VERBOSE
fb = Factbase::Tallied.new(Factbase.new, log)
f = fb.insert
churn = fb.churn
assert churn.inserted == 1
```

Properties are accumulative.
Setting a property again adds a value instead of overwriting:

```ruby
f = fb.insert
f.foo = 42
f.foo = 43
assert(f.foo == 42)
assert(f['foo'] == [42, 43])
fb.query('(eq foo 43)').each do |f|
  assert(f.foo == 42)
  assert(f['foo'].include?(43))
end
```

Deleting while iterating is unsafe and may cause elements to be skipped:

```ruby
fb = Factbase.new
fb.insert.id = 1
fb.insert.id = 2
fb.query('(always)').each do |f|
  fb.query("(eq id #{f.id})").delete!
end
assert(1 == fb.size)
```

To safely delete, use a snapshot:

```ruby
fb = Factbase.new
fb.insert.id = 1
fb.insert.id = 2
fb.query('(always)').to_a.each do |f|
  fb.query("(eq id #{f.id})").delete!
end
assert(0 == fb.size)
```

## Terms

There are some boolean terms available in a query
(they return either `true` or `false`):

* `(always)` and `(never)` are `true` and `false`
* `(nil v)` is `true` if `v` is `nil`
* `(not b)` is the inverse of `b`
* `(or b1 b2 ...)` is `true` if at least one argument is `true`
* `(and b1 b2 ...)` — if all arguments are `true`
* `(when b1 b2)` — if `b1` is `true` and `b2` is `true`
or `b1` is `false`
* `(exists p)` — if `p` property exists
* `(absent p)` — if `p` property is absent
* `(zero v)` — if any `v` equals to zero
* `(eq v1 v2)` — if any `v1` equals to any `v2`
* `(lt v1 v2)` — if any `v1` is less than any `v2`
* `(gt v1 v2)` — if any `v1` is greater than any `v2`
* `(many v)` — if `v` has many values
* `(one v)` — if `v` has one value

There are string manipulators:

* `(concat v1 v2 v3 ...)` — concatenates all `v`
* `(sprintf v v1 v2 ...)` — creates a string by `v` format with params
* `(matches v s)` — if any `v` matches the `s` regular expression

There are a few terms that return non-boolean values:

* `(at i v)` is the `i`-th value of `v`
* `(size v)` is the cardinality of `v` (zero if `v` is `nil`)
* `(type v)` is the type of `v`
(`"String"`, `"Integer"`, `"Float"`, `"Time"`, or `"Array"`)
* `(either v1 v1)` is `v2` if `v1` is `nil`

It's possible to modify the facts retrieved, on fly:

* `(as p v)` adds property `p` with the value `v`
* `(join s t)` adds properties named by the `s` mask with the values retrieved
by the `t` term, for example, `(join "x<=foo,y<=bar" (gt x 5))` will add
`x` and `y` properties, setting them to values found in the `foo` and `bar`
properties in the facts that match `(gt x 5)`

Also, some simple arithmetic:

* `(plus v1 v2)` is a sum of `∑v1` and `∑v2`
* `(minus v1 v2)` is a deduction of `∑v2` from `∑v1`
* `(times v1 v2)` is a multiplication of `∏v1` and `∏v2`
* `(div v1 v2)` is a division of `∏v1` by `∏v2`

It's possible to add and deduct string values to time values, like
`(plus t '2 days')` or `(minus t '14 hours')`.

Types may be converted:

* `(to_int v)` is an integer of `v`
* `(to_str v)` is a string of `v`
* `(to_float v)` is a float of `v`

One term is for meta-programming:

* `(defn f "self.to_s")` defines a new term using Ruby syntax and returns `true`
* `(undef f)` undefines a term (nothing happens if it's not defined yet),
returns `true`

There are terms that are history of search aware:

* `(prev p)` returns the value of `p` property in the previously seen fact
* `(unique p1 p2 ...)` returns true if at least one property value
hasn't been seen yet; returns false when all specified properties
have duplicate values in this particular combination

The `agg` term enables sub-queries by evaluating the first argument (term)
over all available facts, passing the entire subset to the second argument,
and then returning the result as an atomic value:

* `(lt age (agg (eq gender 'F') (max age)))` selects all facts where
the `age` is smaller than the maximum `age` of all women
* `(eq id (agg (always) (max id)))` selects the fact with the largest `id`
* `(eq salary (agg (eq dept $dept) (avg salary)))` selects the facts
with the salary average in their departments

There are also terms that match the entire factbase
and must be used primarily inside the `(agg ..)` term:

* `(nth v p)` returns the `p` property of the _v_-th fact (must be
a positive integer)
* `(first p)` returns the `p` property of the first fact
* `(count)` returns the tally of facts
* `(max p)` returns the maximum value of the `p` property in all facts
* `(min p)` returns the minimum
* `(sum p)` returns the arithmetic sum of all values of the `p` property

It's also possible to use a sub-query in a shorter form than with the `agg`:

* `(empty q)` is true if the subquery `q` is empty

It's possible to post-process a list of facts, for `agg` and `join`:

* `(sorted p expr)` sorts them by the value of `p` property
* `(inverted expr)` reverses them
* `(head n expr)` takes only `n` facts from the head of the list

There are some system-level terms:

* `(env v1 v2)` returns the value of environment variable `v1` or the string
`v2` if it's not set

## How to contribute

Read
[these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).
Make sure your build is green before you contribute
your pull request. You will need to have
[Ruby](https://www.ruby-lang.org/en/) 3.4+ and
[Bundler](https://bundler.io/) installed. Then:

```bash
bundle update
bundle exec rake
```

If it's clean and you don't see any error messages, submit your pull request.

## Benchmark

This is the result of the benchmark:

<!-- benchmark_begin -->
```text
                                                                   user
void scan                                                      0.001233
20k facts: export: 2964KB                                      0.925003
20k facts: import: 2964KB                                      1.066159
50k facts: read                                                0.000200
50k facts: read in txn                                         0.002507
50k facts: insert                                              0.000134
50k facts: insert in txn                                       0.000228
50k facts: modify                                              1.106493
50k facts: modify in txn                                       2.726067
12k facts: large query: match 3k                              13.968585
12k facts: large query: match 3k in txn                       18.660005
12k facts: large query: match zero                            14.504566
12k facts: large query: match zero in txn                     19.837014
```

The results were calculated in [this GHA job][benchmark-gha]
on 2026-03-13 at 19:11,
on Linux with 4 CPUs.
<!-- benchmark_end -->

[benchmark-gha]: https://github.com/yegor256/factbase/actions/runs/23066478431
