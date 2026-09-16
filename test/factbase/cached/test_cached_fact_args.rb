# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/cached/cached_fact'

# Test of the arguments CachedFact takes.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestCachedFactArgs < Factbase::Test
  def test_refuses_an_argument_it_does_not_use
    fact = Factbase.new.insert
    assert_raises(ArgumentError) do
      Factbase::CachedFact.new(fact, {}, fresh: true)
    end
  end
end
