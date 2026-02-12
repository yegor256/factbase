# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

def bench_indexes_terms(bmk, _fb)
  # Total defines the scale of the dataset (number of facts).
  total = 15_000
  pretty_total = total >= 1000 ? "#{total / 1000}k" : total.to_s
  # Iterations (repeats) for each benchmark run.
  iterations = 5
  # Selectivity controls how many facts match the predicate.
  # For example, 2 means 2% of facts will satisfy the condition.
  selectivity = 20
  raise ArgumentError, 'selectivity must be between 0 and 100' unless selectivity.between?(0, 100)
  # Returns true for the first N facts to ensure deterministic selectivity.
  include = ->(i) { i < total * selectivity / 100 }
  # Cardinality defines the diversity of "noise" data (non-matching facts).
  # High cardinality (e.g., 1000) makes matching facts stand out more,
  # while low cardinality (e.g., 2) creates many duplicates, forcing
  # the index to work harder on filtering.
  cardinality = 10
  raise ArgumentError, 'cardinality must be positive' unless cardinality.positive?
  [
    {
      term: 'absent',
      query: '(absent status)',
      seed: lambda { |fb|
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          f.status = 1 if include.call(i)
        end
      }
    },
    {
      term: 'exists',
      query: '(exists status)',
      seed: lambda { |fb|
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          f.status = 1 if include.call(i)
        end
      }
    },
    {
      term: 'eq',
      query: '(eq status 1)',
      seed: lambda { |fb|
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          f.status = include.call(i) ? 1 : rand(2..cardinality)
        end
      }
    },
    {
      term: 'not',
      query: '(not (eq status 1))',
      seed: lambda { |fb|
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          f.status = include.call(i) ? 1 : rand(2..cardinality)
        end
      }
    },
    {
      term: 'gt',
      query: '(gt score 500)',
      seed: lambda { |fb|
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          f.score = include.call(i) ? rand(501..999) : rand(0..500)
        end
      }
    },
    {
      term: 'lt',
      query: '(lt score 500)',
      seed: lambda { |fb|
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          f.score = include.call(i) ? rand(0..499) : rand(500..999)
        end
      }
    },
    {
      term: 'and',
      query: '(and (eq status 1) (gt tag 1))',
      seed: lambda { |fb|
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          matched = include.call(i)
          f.status = matched ? 1 : rand(2..cardinality)
          f.tag = matched ? 1 : rand(2..cardinality)
        end
      }
    },
    {
      term: 'one',
      query: '(one tag)',
      seed: lambda { |fb|
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          matched = include.call(i)
          f.tag = 1
          f.tag = 2 unless matched
        end
      }
    },
    {
      term: 'or',
      query: '(or (eq status 1) (eq tag 1))',
      seed: lambda { |fb|
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          matched = include.call(i)
          f.status = matched ? 1 : rand(2..cardinality)
          f.tag = matched ? 1 : rand(2..cardinality)
        end
      }
    },
    {
      term: 'unique',
      query: '(unique status tag)',
      seed: lambda { |fb|
        gen_unique_pairs = Enumerator.produce([1, 1]) { |a, b| a <= b ? [a + 1, b] : [a, b + 1] }
        # pre-seed pairs array to prevent nil in .sample
        pairs = [gen_unique_pairs.next]
        next_pair = -> { gen_unique_pairs.next.tap { |p| pairs << p } }
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          f.status, f.tag =
            if include.call(i)
              # Create a new unique pair
              next_pair.call
            else
              # Reuse an existing pair
              pairs.sample
            end
        end
      }
    }
  ].each do |c|
    fb_plain = Factbase.new
    c[:seed].call(fb_plain)
    report = "query #{pretty_total} facts  sel: #{selectivity}%  card: #{cardinality} "
    bmk.report("#{report} #{c[:term]} plain") do
      iterations.times { fb_plain.query(c[:query]).each.to_a }
    end
    # force empty index
    idx = {}
    # force empty fresh
    fresh = Set.new
    fb_indexed = Factbase::IndexedFactbase.new(Factbase.new, idx, fresh)
    c[:seed].call(fb_indexed)
    bmk.report("#{report} #{c[:term]} indexed(cold)") do
      fb_indexed.query(c[:query].to_s).each.to_a
    end
    # force warm
    fb_indexed.query(c[:query].to_s).each.to_a
    bmk.report("#{report} #{c[:term]} indexed(warm)") do
      iterations.times { fb_indexed.query(c[:query].to_s).each.to_a }
    end
  end
end
