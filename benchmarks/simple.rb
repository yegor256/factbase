#!/usr/bin/env ruby
# frozen_string_literal: true

# Copyright (c) 2024-2025 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'benchmark'
require 'time'

require_relative '../lib/factbase'

QUERY_RUNS = 10
TRANSACTION_RUNS = 1_000
INSERTION_COUNT = 100

sum = {}

factbase = Factbase.new
insertion_time =
  Benchmark.measure do
    INSERTION_COUNT.times do |i|
      fact = factbase.insert
      fact.id = i
      fact.title = "Object Thinking #{i}"
      fact.time = Time.now.iso8601
      fact.cost = rand(1..100)
      fact.foo = rand(0.0..100.0).round(3)
      fact.bar = rand(100..300)
      fact.seenBy = "User#{i}" if i.even?
      fact.zzz = "Extra#{i}" if (i % 10).zero?
    end
  end

sum["Inserted #{INSERTION_COUNT} facts"] = insertion_time.real

queries = [
  '(eq title \'Object Thinking 5000\')',
  '(gt time \'2024-03-23T03:21:43Z\')',
  '(and (eq foo 42.998) (or (gt bar 200) (absent zzz)))',
  '(eq id (agg (always) (max id)))',
  '(join "c<=cost,b<=bar" (eq id (agg (always) (max id))))'
]

queries.each do |q|
  time =
    Benchmark.measure do
      QUERY_RUNS.times do
        results = factbase.query(q)
        results.each(&:inspect)
      end
    end
  avg = (time.real / QUERY_RUNS).round(6)
  sum["`#{q}`"] = avg
end

transaction_time =
  Benchmark.measure do
    TRANSACTION_RUNS.times do |i|
      factbase.txn do |fb_txn|
        fact = fb_txn.insert
        fact.id = INSERTION_COUNT + i
        fact.title = "Transaction Fact #{i}"
        fact.time = Time.now.iso8601
        fact.cost = rand(1..100)
        fact.foo = rand(0.0..100.0).round(3)
        fact.bar = rand(100..300)
        raise Factbase::Rollback, 'Cost below threshold' if fact.cost < 10
      rescue Factbase::Rollback
        # ignore
      end
    end
  end

sum['Transaction committed'] = transaction_time.real / TRANSACTION_RUNS

export_time =
  Benchmark.measure do
    factbase.export
  end
sum['Factbase exported'] = export_time.real

import_time =
  Benchmark.measure do
    new_factbase = Factbase.new
    exported_data = factbase.export
    new_factbase.import(exported_data)
  end
sum['Factbase imported'] = import_time.real

puts '| What | Seconds |'
puts '| --- | --: |'
sum.each { |k, v| puts "| #{k} | #{format('%0.3f', v)} |" }
