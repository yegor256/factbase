# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'loog'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/churn'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestChurn < Minitest::Test
  def test_appends
    c = Factbase::Churn.new
    c.append(1, 2, 3)
    assert_equal('1i/2d/3a', c.to_s)
  end

  def test_checks_for_zero
    c = Factbase::Churn.new
    assert_predicate(c, :zero?)
  end

  def test_makes_a_duplicate
    c = Factbase::Churn.new
    assert_predicate(c.dup, :zero?)
  end
end
