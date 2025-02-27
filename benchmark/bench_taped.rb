# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/factbase'
require_relative '../lib/factbase/taped'

def bench_taped(bmk, fb)
  maps = []
  taped = Factbase::Taped.new(maps)

  cycles = 10_000
  bmk.report('Taped.append()') do
    cycles.times do
      taped << { foo: rand(0..100) }
    end
  end

  bmk.report('Taped.each()') do
    cycles.times do
      taped.each.to_a
    end
  end

  bmk.report('Taped.delete_if()') do
    cycles.times do
      taped.delete_if { |m| m[:foo] < 50 }
    end
  end
end
