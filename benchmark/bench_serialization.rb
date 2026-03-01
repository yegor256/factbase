# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/fuzz'
require_relative '../lib/factbase'

def bench_serialization(bmk, fb, cycles)
  fuzz = Factbase::Fuzz.new
  total = 20_000
  p_total = "#{total / 1000}k"
  fuzz.feed(fb, total)
  bin = fb.export
  size_kb = "#{bin.size / 1024}KB"
  bmk.report("#{p_total} facts: export: #{size_kb}") do
    cycles.times { bin = fb.export }
  end
  size_kb = "#{bin.size / 1024}KB"
  bmk.report("#{p_total} facts: import: #{size_kb}") do
    cycles.times { fb.import(bin) }
  end
end
