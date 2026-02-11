# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

def bench_unique_index(bmk, _fb)
  total = 20_000
  populate =
    lambda do |factbase|
      total.times do |i|
        factbase.insert.then do |f|
          f.id = i
          f.category = %w[A B C D E][i % 5]
          f.color = %w[red green blue][i % 3]
        end
      end
    end
  query = '(unique category color)'
  fb_plain = Factbase.new
  populate.call(fb_plain)
  bmk.report("query #{total} facts without unique index") do
    5.times do
      fb_plain.query(query).each.to_a
    end
  end
  fb_with_index = Factbase::IndexedFactbase.new(Factbase.new)
  populate.call(fb_with_index)
  bmk.report("query #{total} facts with unique index(cold)") do
    fb_with_index.query(query).each.to_a
  end
  bmk.report("query #{total} facts with unique index(warm)") do
    5.times do
      fb_with_index.query(query).each.to_a
    end
  end
end
