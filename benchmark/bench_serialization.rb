# frozen_string_literal: true

require_relative '../lib/factbase'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/fuzz'

def bench_serialization(bmk, fb, cycles)
  total = 20_000
  p_total = "#{total / 1000}k"
  Factbase::Fuzz.new.feed(fb, total)
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
