# frozen_string_literal: true

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/indexed_factbase'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestIndexedExistsParam < Factbase::Test
  def test_resolves_a_parameter
    origin = Factbase.new
    3.times { |i| origin.insert.foo = i }
    fb = Factbase::IndexedFactbase.new(origin)
    ['(exists $x)', '(one $x)'].each do |q|
      assert_equal(origin.query(q).each(origin, x: ['foo']).to_a.size, fb.query(q).each(fb, x: ['foo']).to_a.size, q)
    end
  end
end
