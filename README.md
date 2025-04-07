# Single-Table NoSQL-ish In-Memory Database

[![DevOps By Rultor.com](https://www.rultor.com/b/yegor256/factbase)](https://www.rultor.com/p/yegor256/factbase)
[![We recommend RubyMine](https://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![rake](https://github.com/yegor256/factbase/actions/workflows/rake.yml/badge.svg)](https://github.com/yegor256/factbase/actions/workflows/rake.yml)
[![PDD status](https://www.0pdd.com/svg?name=yegor256/factbase)](https://www.0pdd.com/p?name=yegor256/factbase)
[![Gem Version](https://badge.fury.io/rb/factbase.svg)](https://badge.fury.io/rb/factbase)
[![Test Coverage](https://img.shields.io/codecov/c/github/yegor256/factbase.svg)](https://codecov.io/github/yegor256/factbase?branch=master)
[![Yard Docs](https://img.shields.io/badge/yard-docs-blue.svg)](https://rubydoc.info/github/yegor256/factbase/master/frames)
[![Hits-of-Code](https://hitsofcode.com/github/yegor256/factbase)](https://hitsofcode.com/view/github/yegor256/factbase)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/yegor256/factbase/blob/master/LICENSE.txt)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fyegor256%2Ffactbase.svg?type=shield&issueType=license)](https://app.fossa.com/projects/git%2Bgithub.com%2Fyegor256%2Ffactbase?ref=badge_shield&issueType=license)

This Ruby gem manages an in-memory database of facts.
A fact is simply a map of properties and values.
The values are either atomic literals or non-empty sets of literals.
It is possible to delete a fact, but impossible to delete a property
from a fact.

**ATTENTION**: The current implementation is naive and,
because of that, **very slow**. I will be very happy
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
* `(minus v1 v2)` is a deducation of `∑v2` from `∑v1`
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
* `(unique p)` returns true if the value of `p` property hasn't been seen yet

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

There are some system-level terms:

* `(env v1 v2)` returns the value of environment variable `v1` or the string
`v2` if it's not set

## How to contribute

Read
[these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).
Make sure your build is green before you contribute
your pull request. You will need to have
[Ruby](https://www.ruby-lang.org/en/) 3.2+ and
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
                                                                   user     system      total        real
insert 20000 facts                                             0.584619   0.003744   0.588363 (  0.588372)
export 20000 facts                                             0.019872   0.004992   0.024864 (  0.024870)
import 411135 bytes (20000 facts)                              0.030978   0.004000   0.034978 (  0.034983)
insert 10 facts                                                0.043662   0.002056   0.045718 (  0.045738)
query 10 times w/txn                                           1.809973   0.034886   1.844859 (  1.845456)
query 10 times w/o txn                                         0.039074   0.004004   0.043078 (  0.043081)
modify 10 attrs w/txn                                          1.705921   0.015961   1.721882 (  1.722316)
delete 10 facts w/txn                                          1.021624   0.007014   1.028638 (  1.028692)
(and (eq what 'issue-was-closed') (exists... -> 200            2.110981   0.005000   2.115981 (  2.116099)
(and (eq what 'issue-was-closed') (exists... -> 200/txn        1.125909   0.000000   1.125909 (  1.125962)
(and (eq what 'issue-was-closed') (exists... -> zero           2.417743   0.000993   2.418736 (  2.418869)
(and (eq what 'issue-was-closed') (exists... -> zero/txn       1.282409   0.003006   1.285415 (  1.285498)
(gt time '2024-03-23T03:21:43Z')                               0.092167   0.000000   0.092167 (  0.092169)
(gt cost 50)                                                   0.107435   0.000000   0.107435 (  0.107438)
(eq title 'Object Thinking 5000')                              0.002544   0.000000   0.002544 (  0.002546)
(and (eq foo 42.998) (or (gt bar 200) (absent zzz)))           0.022142   0.000000   0.022142 (  0.022143)
(eq id (agg (always) (max id)))                                0.244818   0.000000   0.244818 (  0.244835)
(join "c<=cost,b<=bar" (eq id (agg (always) (max id))))        0.672133   0.001998   0.674131 (  0.674186)
delete!                                                        0.074661   0.000000   0.074661 (  0.074663)
Taped.append() x50000                                          0.037757   0.004997   0.042754 (  0.042759)
Taped.each() x125                                              1.283630   0.001995   1.285625 (  1.285706)
Taped.delete_if() x375                                         0.819901   0.000000   0.819901 (  0.819968)
```

The results were calculated in [this GHA job][benchmark-gha]
on 2025-04-07 at 10:33,
on Linux with 4 CPUs.
<!-- benchmark_end -->

[benchmark-gha]: https://github.com/yegor256/factbase/actions/runs/14306969571
