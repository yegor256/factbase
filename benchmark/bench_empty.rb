# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/factbase'

def bench_empty(bmk, fb)
  bmk.report('query all facts from an empty factbase') do
    size = fb.query('(always)').count
    raise "Expected zero facts in an empty factbase, got #{size}" unless size.zero?
  end
end
