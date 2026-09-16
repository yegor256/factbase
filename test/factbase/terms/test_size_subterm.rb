# frozen_string_literal: true

require_relative '../../../lib/factbase'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test of the terms that inspect a value, over a nested term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestSizeSubterm < Factbase::Test
  def test_size_of_a_sub_term
    assert_equal([1], first('(as r (size (minus foo bar)))'))
  end

  def test_type_of_a_sub_term
    assert_equal(['Integer'], first('(as r (type (minus foo bar)))'))
  end

  def test_exists_of_a_sub_term
    assert_equal([true], first('(as r (exists (minus foo bar)))'))
  end

  def test_absent_of_a_sub_term
    assert_equal([false], first('(as r (absent (minus foo bar)))'))
  end

  private

  def first(query)
    fb = Factbase.new
    f = fb.insert
    f.foo = 7
    f.bar = 3
    fb.query(query).each.to_a.first['r']
  end
end
