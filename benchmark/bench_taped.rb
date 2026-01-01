# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/factbase'
require_relative '../lib/factbase/taped'

def bench_taped(bmk, _fb)
  maps = []
  taped = Factbase::Taped.new(maps)

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

  cycles *= 3
  bmk.report("Taped.delete_if() x#{cycles}") do
    cycles.times do
      taped.delete_if { |m| m[:foo] < 50 }
    end
  end
end
