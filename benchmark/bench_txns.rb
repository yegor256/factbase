# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/fuzz'
require_relative '../lib/factbase'

# To run this benchmark, use:
# bundle exec rake benchmark\[bench_txns\]
def bench_txns(bmk, _fb, cycles)
  totals = [50_000]
  fuzz = Factbase::Fuzz.new
  totals.each do |total|
    p_total = "#{total / 1000}k"
    fb_read_plain = Factbase.new.tap { |f| fuzz.feed(f, total) }
    raise 'not enough facts' unless fb_read_plain.query('(always)').each.any?
    bmk.report("#{p_total} facts: read") do
      cycles.times { fb_read_plain.query('(always)').each.size }
    end
    fb_read_txn = Factbase.new.tap { |f| fuzz.feed(f, total) }
    raise 'not enough facts' unless fb_read_txn.query('(always)').each.any?
    bmk.report("#{p_total} facts: read in txn") do
      cycles.times do
        fb_read_txn.txn { |fbt| fbt.query('(always)').each.size }
      end
    end
    fb_ins_plain = Factbase.new.tap { |f| fuzz.feed(f, total) }
    raise 'not enough facts' unless fb_ins_plain.query('(always)').each.any?
    bmk.report("#{p_total} facts: insert") do
      cycles.times { fb_ins_plain.insert.bar = 999 }
    end
    fb_ins_txn = Factbase.new.tap { |f| fuzz.feed(f, total) }
    raise 'not enough facts' unless fb_ins_txn.query('(always)').each.any?
    bmk.report("#{p_total} facts: insert in txn") do
      cycles.times do
        fb_ins_txn.txn do |fbt|
          fbt.insert.bar = 999
          raise Factbase::Rollback
        end
      end
    end
    fb_mod_plain = Factbase.new.tap { |f| fuzz.feed(f, total) }
    fb_mod_plain.query('(always)').each.take(cycles).each { |f| f.foo = 0 }
    raise 'not enough facts' if fb_mod_plain.query('(eq foo 0)').each.to_a.size != cycles
    bmk.report("#{p_total} facts: modify") do
      cycles.times do
        fb_mod_plain.query('(eq foo 0)').each { |f| f.bar = 1 }
      end
    end
    fb_mod_txn = Factbase.new.tap { |f| fuzz.feed(f, total) }
    fb_mod_txn.query('(always)').each.take(cycles).each { |f| f.foo = 0 }
    raise 'not enough facts' if fb_mod_txn.query('(eq foo 0)').each.to_a.size != cycles
    bmk.report("#{p_total} facts: modify in txn") do
      cycles.times do
        fb_mod_txn.txn do |fbt|
          fbt.query('(eq foo 0)').each { |f| f.bar = 1 }
          raise Factbase::Rollback
        end
      end
    end
  end
end
