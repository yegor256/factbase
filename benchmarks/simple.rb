#!/usr/bin/env ruby
# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'benchmark'
require 'time'
require_relative '../lib/factbase'

def insert(fb, total)
  time =
    Benchmark.measure do
      total.times do |i|
        fact = fb.insert
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
  {
    title: '`fb.insert()`',
    time: time.real,
    details: "Inserted #{total} facts"
  }
end

def query(fb, query)
  total = 0
  runs = 10
  time =
    Benchmark.measure do
      runs.times do
        total = fb.query(query).each.to_a.size
      end
    end
  {
    title: "`#{query}`",
    time: (time.real / runs).round(6),
    details: "Found #{total} fact(s)"
  }
end

def delete(fb, query)
  total = 0
  time =
    Benchmark.measure do
      total = fb.query(query).delete!
    end
  {
    title: "`#{query}`",
    time: time.real.round(6),
    details: "Deleted #{total} fact(s)"
  }
end

def impex(fb)
  size = 0
  time =
    Benchmark.measure do
      bin = fb.export
      size = bin.size
      fb2 = Factbase.new
      fb2.import(bin)
    end
  {
    title: '`.export()` + `.import()`',
    time: time.real,
    details: "#{size} bytes"
  }
end

def txn(fb, scenario, &block)
  time =
    Benchmark.measure do
      fb.txn(&block)
    end
  {
    title: "txn: #{scenario}",
    time: time.real,
    details: ''
  }
end

fb = Factbase.new
rows = [
  insert(fb, 25_000),
  query(fb, '(gt time \'2024-03-23T03:21:43Z\')'),
  query(fb, '(gt cost 50)'),
  query(fb, '(eq title \'Object Thinking 5000\')'),
  query(fb, '(and (eq foo 42.998) (or (gt bar 200) (absent zzz)))'),
  query(fb, '(eq id (agg (always) (max id)))'),
  query(fb, '(join "c<=cost,b<=bar" (eq id (agg (always) (max id))))'),
  txn(fb, 'insert()') do |fbt|
    100.times do
      fbt.insert
    end
  end,
  txn(fb, 'add()') do |fbt|
    100.times do |i|
      fbt.query("(gt foo #{i})").each.to_a.first.bar = 55
    end
  end,
  txn(fb, 'delete!()') do |fbt|
    100.times do |i|
      fbt.query("(gt foo #{i})").delete!
    end
  end,
  impex(fb),
  delete(fb, '(gt cost 50)'),
  delete(fb, '(gt foo 1)')
].map { |r| "| #{r[:title]} | #{format('%0.3f', r[:time])} | #{r[:details]} |" }

puts '| Action | Seconds | Details |'
puts '| --- | --: | --- |'
rows.each { |row| puts row }
