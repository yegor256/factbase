# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/factbase'
require_relative '../lib/factbase/logged'

def bench_large_query(bmk, fb)
  total = 200
  repo = 'foo'
  total.times do |i|
    f = fb.insert
    f.id = i
    f.where = 'github'
    f.what = 'issue-was-closed'
    f.who = 444
    f.when = Time.now - (i * rand(1_000..100_000))
    f.issue = i
    f.repository = repo
  end
  total.times do |i|
    f = fb.insert
    f.id = i + total
    f.where = 'github'
    f.what = 'label-was-attached'
    f.when = Time.now - (i * rand(1_000..100_000))
    f.issue = i
    f.repository = repo
    f.label = 'bug'
  end
  total.times do |i|
    f = fb.insert
    f.id = i + (total * 2)
    f.where = 'github'
    f.what = 'issue-was-opened'
    f.who = 555
    f.when = Time.now - (i * rand(1_000..100_000))
    f.issue = i
    f.repository = repo
  end
  total.times do |i|
    f = fb.insert
    f.id = i + (total * 3)
    f.where = 'github'
    f.what = 'issue-was-assigned'
    f.who = 666
    f.when = Time.now - (i * rand(1_000..100_000))
    f.issue = i
    f.repository = repo
  end

  q = "(and
    (eq what 'issue-was-closed')
    (exists where)
    (exists who)
    (exists when)
    (exists issue)
    (exists repository)
    (join 'label' (and
      (eq what 'label-was-attached')
      (eq issue $issue)
      (eq where $where)
      (eq repository $repository)
      (or (eq label 'bug') (eq label 'enhancement') (eq label 'question'))))
    (exists label)
    (join 'opened_when<=when,opener<=who' (and
      (eq what 'issue-was-opened')
      (eq where $where)
      (eq issue $issue)
      (eq repository $repository)))
    (exists opener)
    (join 'assigned_when<=when,assigner<=who' (and
      (eq what 'issue-was-assigned')
      (eq where $where)
      (eq issue $issue)
      (eq repository $repository)))
    (exists assigner)
    (as seconds (to_integer (minus when assigned_when)))
    (as closer who)
    (as who assigner)
    (empty (and
      (eq what 'bug-was-resolved')
      (eq where $where)
      (eq issue $issue)
      (eq repository $repository))))".gsub(/\s+/, ' ')

  cycles = 1
  bmk.report("#{q[0..40]}...") do
    cycles.times do
      t = fb.query(q).each.to_a.size
      raise "Found #{t} facts, expected to find #{total}" unless t == total
    end
  end
end
