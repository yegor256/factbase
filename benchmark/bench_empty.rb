# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/factbase'

def bench_empty(bmk, fb, cycles)
  bmk.report('void scan') do
    cycles.times do
      size = fb.query('(always)').count
      raise "Expected 0, got #{size}" unless size.zero?
    end
  end
end
