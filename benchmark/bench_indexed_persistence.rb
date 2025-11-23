# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/factbase'

def bench_indexed_persistence(bmk, _fb)
  total = 5_000
  fb_source = Factbase::IndexedFactbase.new(Factbase.new)
  total.times do |i|
    fb_source.insert.then do |f|
      f.id = i
      f.value = i % 100
      f.category = %w[A B C D E][i % 5]
      f.score = rand(0..1000)
    end
  end
  bmk.report("build index on #{total} facts") do
    fb_source.query('(eq value 42)').each.to_a
    fb_source.query('(eq category "A")').each.to_a
    fb_source.query('(gt score 500)').each.to_a
  end
  data_with_index = nil
  bmk.report("export #{total} facts with index") do
    data_with_index = fb_source.export
  end
  bmk.report("import #{total} facts with persisted index") do
    fb_with = Factbase::IndexedFactbase.new(Factbase.new)
    fb_with.import(data_with_index)
  end
  fb_with_index = Factbase::IndexedFactbase.new(Factbase.new)
  fb_with_index.import(data_with_index)
  bmk.report("query #{total} facts using persisted index") do
    3.times do
      fb_with_index.query('(eq value 42)').each.to_a
      fb_with_index.query('(eq category "A")').each.to_a
      fb_with_index.query('(gt score 500)').each.to_a
    end
  end
  fb_plain = Factbase.new
  total.times do |i|
    fb_plain.insert.then do |f|
      f.id = i
      f.value = i % 100
      f.category = %w[A B C D E][i % 5]
      f.score = rand(0..1000)
    end
  end
  data_without_index = nil
  bmk.report("export #{total} facts without index") do
    data_without_index = fb_plain.export
  end
  bmk.report("import #{total} facts without index") do
    fb_without = Factbase::IndexedFactbase.new(Factbase.new)
    fb_without.import(data_without_index)
  end
  fb_without_index = Factbase::IndexedFactbase.new(Factbase.new)
  fb_without_index.import(data_without_index)
  bmk.report("query #{total} facts building index on-the-fly") do
    3.times do
      fb_without_index.query('(eq value 42)').each.to_a
      fb_without_index.query('(eq category "A")').each.to_a
      fb_without_index.query('(gt score 500)').each.to_a
    end
  end
end
