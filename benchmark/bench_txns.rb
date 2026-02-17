# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/factbase'

# To run this benchmark, use:
# bundle exec rake benchmark\[bench_txns\]
def bench_txns(bmk, _fb)
  sizes = [50_000, 100_000]
  repeats = 100
  feed =
    lambda do |fb, size|
      size.times { |i| fb.insert.foo = i }
      fb
    end
  sizes.each do |size|
    fb_read_plain = feed.call(Factbase.new, size)
    bmk.report("#{size} facts: plain read (no txn)") do
      repeats.times { fb_read_plain.query('(always)').each.to_a.size }
    end
    fb_read_txn = feed.call(Factbase.new, size)
    bmk.report("#{size} facts: read-only txn (no copy)") do
      repeats.times do
        fb_read_txn.txn { |fbt| fbt.query('(always)').each.to_a.size }
      end
    end
    fb_ins_plain = feed.call(Factbase.new, size)
    bmk.report("#{size} facts: plain insert (no txn)") do
      repeats.times { fb_ins_plain.insert.bar = 999 }
    end
    fb_ins_txn = feed.call(Factbase.new, size)
    bmk.report("#{size} facts: insert in txn (copy triggered)") do
      repeats.times do
        fb_ins_txn.txn do |fbt|
          fbt.insert.bar = 999
          raise Factbase::Rollback
        end
      end
    end
    fb_mod_plain = feed.call(Factbase.new, size)
    bmk.report("#{size} facts: plain modify (no txn)") do
      repeats.times do
        fb_mod_plain.query('(eq foo 0)').each { |f| f.bar = 1 }
      end
    end
    fb_mod_txn = feed.call(Factbase.new, size)
    bmk.report("#{size} facts: modify in txn (copy triggered)") do
      repeats.times do
        fb_mod_txn.txn do |fbt|
          fbt.query('(eq foo 0)').each { |f| f.bar = 1 }
          raise Factbase::Rollback
        end
      end
    end
  end
end
