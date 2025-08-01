# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'ellipsized'
require 'timeout'
require_relative '../lib/factbase'

def bench_query(bmk, fb)
  total = 20_000
  total.times do |i|
    f = fb.insert
    f.what = 'foo'
    f.where = 'github'
    f.id = i
    f.title = "Object Thinking #{i}"
    f.time = Time.now.iso8601
    f.cost = rand(1..100)
    f.foo = rand(0.0..100.0).round(3)
    f.bar = rand(100..300)
    f.blue = 1 if rand > 0.5
    f.seenBy = "User#{i}" if i.even?
    f.zzz = "Extra#{i}" if (i % 10).zero?
  end

  runs = 3
  [
    '(gt time \'2024-03-23T03:21:43Z\')',
    '(gt cost 50)',
    '(eq title \'Object Thinking 5000\')',
    '(and (eq foo 42.998) (or (gt bar 200) (absent zzz)))',
    '(and (exists foo) (not (exists blue)))',
    '(eq id (agg (always) (max id)))',
    '(join "c<=cost,b<=bar" (eq id (agg (always) (max id))))',
    '(and
      (eq what "foo")
      (join "w<=what"
        (and
          (eq id $id)
          (eq what "foo")
          (eq where "github")))
      (assert "has it" (one id)))'
  ].each do |q|
    bmk.report(q.tr("\n", ' ').gsub(/\s+/, ' ').ellipsized(50, :right)) do
      Timeout.timeout(runs * 3) do
        runs.times do
          fb.query(q).each.to_a
        end
      end
    end
  end

  bmk.report('delete!') do
    fb.query('(gt foo 50)').delete!
  end
end
