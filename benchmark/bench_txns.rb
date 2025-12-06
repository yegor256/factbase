# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/factbase'

# To run this benchmark, use:
# bundle exec rake benchmark\[bench_txns\]
def bench_txns(bmk, _fb)
  sizes = [50_000, 100_000]
  sizes.each do |size|
    fb = Factbase.new
    size.times { |i| fb.insert.foo = i }
    bmk.report("#{size} facts: read-only txn (no copy needed)") do
      100.times do
        fb.txn do |fbt|
          fbt.query('(always)').each.to_a.size
        end
      end
    end
    bmk.report("#{size} facts: rollback txn (no copy needed)") do
      100.times do
        fb.txn do |fbt|
          fbt.query('(always)').each.to_a
          raise Factbase::Rollback
        end
      end
    end
    bmk.report("#{size} facts: insert in txn (copy triggered)") do
      100.times do
        fb.txn do |fbt|
          fbt.insert.bar = 999
          raise Factbase::Rollback
        end
      end
    end
    bmk.report("#{size} facts: modify in txn (copy triggered)") do
      100.times do
        fb.txn do |fbt|
          fbt.query('(eq foo 0)').each { |f| f.bar = 1 }
          raise Factbase::Rollback
        end
      end
    end
  end
end
