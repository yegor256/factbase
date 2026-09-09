# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/impatient'
require_relative '../../lib/factbase/logged'
require_relative '../../lib/factbase/tallied'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestDecoratedQueryEnumerable < Factbase::Test
  def test_maps_a_decorated_query
    [
      Factbase::Logged.new(Factbase.new, Loog::NULL),
      Factbase::Impatient.new(Factbase.new),
      Factbase::Tallied.new(Factbase.new)
    ].each do |fb|
      fb.insert.foo = 1
      fb.insert.foo = 2
      q = fb.query('(exists foo)')
      assert_equal(2, q.to_a.size)
      assert_equal([1, 2], q.map(&:foo))
    end
  end
end
