# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/factbase'
require_relative '../lib/factbase/taped'

def bench_taped(bmk, _fb, _)
  taped = Factbase::Taped.new([])
  cycles = 50_000
  bmk.report("Taped.append() x#{cycles}") do
    cycles.times do
      taped << { foo: rand(0..100) }
    end
  end
  cycles /= 400
  bmk.report("Taped.each() x#{cycles}") do
    cycles.times do
      taped.each.to_a
    end
  end
  cycles = 10
  data = taped.each.map { |m| { foo: m[:foo] } }
  copies = Array.new(cycles) { Factbase::Taped.new(data.map(&:dup)) }
  bmk.report("Taped.delete_if() x#{cycles}") do
    copies.each do |copy|
      copy.delete_if { |m| m[:foo] < 50 }
    end
  end
end
