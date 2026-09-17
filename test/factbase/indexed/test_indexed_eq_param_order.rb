# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedEqParamOrder < Factbase::Test
  def test_yields_in_insertion_order
    origin = Factbase.new
    %w[p q r].each_with_index do |label, i|
      f = origin.insert
      f.label = label
      f.a = i.zero? ? 1 : 2
      f.b = 'x'
    end
    fb = Factbase::IndexedFactbase.new(origin)
    ['(eq a $p)', '(and (eq b "x") (eq a $p))'].each do |q|
      assert_equal(
        origin.query(q).each(origin, p: [2, 1]).to_a.map(&:label),
        fb.query(q).each(fb, p: [2, 1]).to_a.map(&:label),
        q
      )
    end
  end
end
