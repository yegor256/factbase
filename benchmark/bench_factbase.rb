# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/factbase'

def bench_factbase(bmk, fb)
  total = 20_000
  bmk.report("insert #{total} facts") do
    total.times do
      fact = fb.insert
      fact.foo = rand(0.0..100.0).round(3)
      fact.bar = rand(100..300)
    end
  end

  bin = nil
  bmk.report("export #{total} facts") do
    bin = fb.export
  end
  bmk.report("import #{bin.size} bytes (#{total} facts)") do
    fb2 = Factbase.new
    fb2.import(bin)
  end

  actions = 10
  bmk.report("insert #{actions} facts") do
    fb.txn do |fbt|
      actions.times do
        fbt.insert.z = rand(0..100)
      end
    end
  end
  bmk.report("query #{actions} times w/txn") do
    fb.txn do |fbt|
      actions.times do |i|
        fbt.query("(gt foo #{i})").each.to_a.each
      end
    end
  end
  bmk.report("query #{actions} times w/o txn") do
    actions.times do |i|
      fb.query("(gt foo #{i})").each.to_a.each
    end
  end
  bmk.report("modify #{actions} attrs w/txn") do
    fb.txn do |fbt|
      actions.times do |i|
        fbt.query("(gt foo #{i})").each.to_a.first.bar = 55
      end
    end
  end
  bmk.report("delete #{actions} facts w/txn") do
    fb.txn do |fbt|
      actions.times do |i|
        fbt.query("(gt foo #{100 - i})").delete!
      end
    end
  end
end
