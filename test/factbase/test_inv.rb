# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require 'loog'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/inv'
require_relative '../../lib/factbase/pre'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestInv < Factbase::Test
  def test_simple_checking
    fb =
      Factbase::Inv.new(Factbase.new) do |p, v|
        raise 'oops' if v.is_a?(String) && p == 'b'
      end
    f = fb.insert
    f.a = 42
    assert_raises(StandardError) do
      f.b = 'here we should crash'
    end
    f.c = 256
    assert_equal(42, f.a)
    assert_equal(1, fb.query('(always)').each.to_a.size)
  end

  def test_pre_and_inv
    fb =
      Factbase::Inv.new(Factbase.new) do |p, v|
        raise 'oops' if v.is_a?(String) && p == 'b'
      end
    fb =
      Factbase::Pre.new(fb) do |f|
        f.id = 42
      end
    f = fb.insert
    assert_equal(42, f.id)
  end
end
