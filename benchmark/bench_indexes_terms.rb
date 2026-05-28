# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

def bench_indexes_terms(bmk, _fb, cycles)
  total = 15_000
  pretty_total = total >= 1000 ? "#{total / 1000}k" : total.to_s
  selectivity = 20
  raise(ArgumentError, 'selectivity must be between 0 and 100') unless selectivity.between?(0, 100)
  include = ->(i) { i <= total * selectivity / 100 }
  cardinality = 10
  raise(ArgumentError, 'cardinality must be positive') unless cardinality.positive?
  [
    {
      term: 'absent',
      query: '(absent status)',
      seed: lambda do |fb|
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          f.status = 1 unless include.call(i)
        end
      end
    },
    {
      term: 'exists',
      query: '(exists status)',
      seed: lambda do |fb|
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          f.status = 1 if include.call(i)
        end
      end
    },
    {
      term: 'eq',
      query: '(eq status 1)',
      seed: lambda do |fb|
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          f.status = include.call(i) ? 1 : rand(2..cardinality)
        end
      end
    },
    {
      term: 'not',
      query: '(not (eq status 1))',
      seed: lambda do |fb|
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          f.status = include.call(i) ? rand(2..cardinality) : 1
        end
      end
    },
    {
      term: 'gt',
      query: '(gt score 500)',
      seed: lambda do |fb|
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          f.score = include.call(i) ? rand(501..999) : rand(0..500)
        end
      end
    },
    {
      term: 'lt',
      query: '(lt score 500)',
      seed: lambda do |fb|
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          f.score = include.call(i) ? rand(0..499) : rand(500..999)
        end
      end
    },
    {
      term: 'and eq',
      query: '(and (eq status 1) (eq tag 1))',
      seed: lambda do |fb|
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          matched = include.call(i)
          f.status = matched ? 1 : rand(2..cardinality)
          f.tag = matched ? 1 : rand(2..cardinality)
        end
      end
    },
    {
      term: 'and complex',
      query: '(and (eq status 1) (absent tag))',
      seed: lambda do |fb|
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          matched = include.call(i)
          if matched
            f.status = 1
          else
            f.status = 0
            f.tag = 1
          end
        end
      end
    },
    {
      term: 'one',
      query: '(one tag)',
      seed: lambda do |fb|
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          matched = include.call(i)
          f.tag = 1
          f.tag = 2 unless matched
        end
      end
    },
    {
      term: 'or',
      query: '(or (eq status 1) (eq tag 1))',
      seed: lambda do |fb|
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          matched = include.call(i)
          f.status = matched ? 1 : rand(2..cardinality)
          f.tag = matched ? 1 : rand(2..cardinality)
        end
      end
    },
    {
      term: 'unique',
      query: '(unique status tag)',
      seed: lambda do |fb|
        gen_unique_pairs = Enumerator.produce([1, 1]) { |a, b| a <= b ? [a + 1, b] : [a, b + 1] }
        pairs = [gen_unique_pairs.next]
        next_pair =
          lambda do
            gen_unique_pairs.next.tap { |p| pairs << p }
          end
        (1..total).each do |i|
          f = fb.insert.tap { |f| f.id = i }
          f.status, f.tag =
            if include.call(i)
              next_pair.call
            else
              pairs.sample
            end
        end
      end
    }
  ].each do |c|
    fb_plain = Factbase.new
    c[:seed].call(fb_plain)
    report = "#{pretty_total} facts sel: #{selectivity}% card: #{cardinality} term:"
    bmk.report("#{report} #{c[:term]}: plain scan") do
      cycles.times { fb_plain.query(c[:query]).each.to_a }
    end
    fb_cold = Factbase.new
    c[:seed].call(fb_cold)
    bmk.report("#{report} #{c[:term]}: indexed cold") do
      cycles.times do
        idx = {}
        fresh = Set.new
        Factbase::IndexedFactbase.new(fb_cold, idx, fresh).query(c[:query].to_s).each.to_a
      end
    end
    idx = {}
    fresh = Set.new
    fb_indexed_warm = Factbase::IndexedFactbase.new(Factbase.new, idx, fresh)
    c[:seed].call(fb_indexed_warm)
    fb_indexed_warm.query(c[:query].to_s).each.to_a
    bmk.report("#{report} #{c[:term]}: indexed warm") do
      cycles.times { fb_indexed_warm.query(c[:query].to_s).each.to_a }
    end
  end
end
