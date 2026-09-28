# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
require_relative '../../test__helper'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedExistsShrink < Factbase::Test
  def test_answers_a_query_over_an_array_that_shrank
    assert_equal(asked('(one x)'), asked('(exists x)'))
  end

  private

  def asked(query)
    maps = []
    5.times { |i| maps << { 'x' => [i] } }
    fb = Factbase::IndexedFactbase.new(Factbase.new)
    fb.query(query, maps).each(fb, {}).to_a
    maps.pop(3)
    fb.query(query, maps).each(fb, {}).to_a.size
  end
end
