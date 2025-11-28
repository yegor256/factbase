# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'threads'
require_relative '../lib/factbase'

# This benchmark was added to mitigate the following issue:
# https://github.com/yegor256/factbase/issues/245#issuecomment-3476061847
# It ensures that complex queries run appropriate time
# To run this benchmark, use:
# bundle exec rake benchmark\[bench_slow_query\]
def bench_slow_query(bmk, fb)
  repos = 1_000
  platfrorms = %w[github gitlab bitbucket]
  actions = %w[issue-was-opened issue-was-closed pr-was-opened pr-was-merged]
  queries = []
  create =
    lambda do |i|
      fact = fb.insert
      repo = rand(1..repos)
      what = actions.sample
      where = platfrorms.sample
      fact.issue = i
      fact.repository = repo
      fact.what = what
      fact.where = where
      queries << "(and (eq issue #{i}) (eq repository #{repo}) (eq what '#{what}') (eq where '#{where}'))"
    end
  10_000.times do |i|
    create.call(i + 1)
  end
  bmk.report("(and (eq issue *) (eq repository *) (eq what '*') (eq where '*'))") do
    Threads.new(Concurrent.processor_count * 20, task_timeout: 20, shutdown_timeout: 60).assert do
      # create.call(i + 1) slows down the benchmark significantly
      # with: 16.679675 sec
      # without: 0.212369 sec
      create.call(rand(10_000))
      size = fb.query(queries.sample).count
      raise "Expected to find at least one fact, but got #{size}" if size.zero?
    end
  end
end
