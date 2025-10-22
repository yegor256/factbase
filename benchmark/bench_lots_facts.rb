# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/factbase'
require_relative '../lib/factbase/logged'

def bench_lots_facts(bmk, fb)
  total = 100_000
  total.times do |i|
    f = fb.insert
    f.id = i
    f.time = Time.now
    f.label = %w[bug feature][rand(0..1)]
    f.rpository = 'factbase' if rand(0..1).zero?
  end
  bmk.report("transaction rollback on factbase with #{total} facts") do
    fb.txn do |fbt|
      100.times do |i|
        f = fbt.insert
        f.id = total + i
        f.transaction = 'done'
      end
      raise Factbase::Rollback
    end
    query = fb.query('(agg (exists transaction) (count))')
    raise "Unexpected result for: #{query}" unless query.one.zero?
  end
end
