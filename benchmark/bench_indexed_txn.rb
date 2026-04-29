# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/factbase'
require_relative '../lib/factbase/indexed/indexed_factbase'

# Benchmark for issue #321: index must survive insert-only transactions.
# With IndexedFactbase wrapping, repeated queries after insert-only txns
# should reuse the warm index rather than rebuild it from scratch each time.
#
# To run: bundle exec rake benchmark[bench_indexed_txn]
def bench_indexed_txn(bmk, _fb, cycles)
  total = 100_000
  [total].each do |n|
    p_total = "#{n / 1_000}k"

    # Query after insert-only txn: index should stay warm
    fb_ins = Factbase::IndexedFactbase.new(Factbase.new)
    n.times { |i| fb_ins.insert.tap { |f| f.id = i; f.type = 'issue'; f.status = i < 10 ? 'open' : 'closed' } }
    bmk.report("#{p_total} facts: query after insert txn") do
      cycles.times do |i|
        fb_ins.txn { |fbt| fbt.insert.tap { |f| f.id = n + i; f.type = 'comment' } }
        fb_ins.query("(and (eq type 'issue') (eq status 'open'))").each.size
      end
    end

    # Query after delete txn: index must be cleared (correctness check)
    fb_del = Factbase::IndexedFactbase.new(Factbase.new)
    n.times { |i| fb_del.insert.tap { |f| f.id = i; f.type = 'issue'; f.status = 'open' } }
    bmk.report("#{p_total} facts: query after delete txn") do
      cycles.times do
        fb_del.txn { |fbt| fbt.insert.tap { |f| f.type = 'tmp'; f.status = 'tmp' } }
        fb_del.query("(and (eq type 'issue') (eq status 'open'))").each.size
      end
    end
  end
end
