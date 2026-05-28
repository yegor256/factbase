# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require 'loog'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/churn'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestChurn < Factbase::Test
  def test_appends
    c = Factbase::Churn.new
    c.append(1, 2, 3)
    assert_equal('1i/2d/3a', c.to_s)
    assert_equal(6, c.to_i)
  end

  def test_converts_empty_to_string
    assert_equal('nothing', Factbase::Churn.new.to_s)
  end

  def test_checks_for_zero
    assert_predicate(Factbase::Churn.new, :zero?)
  end

  def test_makes_a_duplicate
    assert_predicate(Factbase::Churn.new.dup, :zero?)
  end

  def test_concatenates_with_other
    c1 = Factbase::Churn.new
    c1.append(1, 6, 3)
    c2 = Factbase::Churn.new
    c2.append(3, 2, 46)
    assert_equal('4i/8d/49a', (c1 + c2).to_s)
  end
end
