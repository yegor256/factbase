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
class TestIndexedNotSuperset < Factbase::Test
  def test_keeps_the_facts_the_sub_term_only_guessed
    origin = Factbase.new
    100.times do |i|
      f = origin.insert
      f.a = i % 2
      f.b = i
    end
    fb = Factbase::IndexedFactbase.new(origin)
    [
      '(not (or (eq a 1) (eq b 3)))',
      '(not (and (exists b) (absent a)))',
      '(not (eq a 1))'
    ].each do |q|
      assert_equal(origin.query(q).each.to_a.size, fb.query(q).each.to_a.size, q)
    end
  end
end
