# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/to_string'

require_relative '../../test__helper'

# Test for 'to_string' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToString < Factbase::Test
  def test_to_str
    assert_equal('String', Factbase::ToString.new([Time.now]).evaluate(fact, [], Factbase.new).class.to_s)
  end

  def test_returns_nil_on_empty_array
    assert_nil(Factbase::ToString.new([[]]).evaluate(fact, [], Factbase.new))
  end

  def test_returns_nil_on_absent_attribute
    fb = Factbase.new
    assert_nil(Factbase::ToString.new([:missing_prop]).evaluate(fb.insert, [], fb))
  end

  def test_returns_nil_on_nil_literal
    assert_nil(Factbase::ToString.new([nil]).evaluate(fact, [], Factbase.new))
  end

  def test_converts_integer_to_string
    fb = Factbase.new
    f = fb.insert
    f.count = 42
    assert_equal('42', Factbase::ToString.new([:count]).evaluate(f, [], fb))
  end

  def test_converts_float_to_string
    fb = Factbase.new
    f = fb.insert
    f.ratio = 3.14
    assert_equal('3.14', Factbase::ToString.new([:ratio]).evaluate(f, [], fb))
  end

  def test_converts_time_to_string
    now = Time.now.utc
    fb = Factbase.new
    f = fb.insert
    f.created_at = now
    assert_equal(now.to_s, Factbase::ToString.new([:created_at]).evaluate(f, [], fb))
  end

  def test_converts_symbol_to_string
    assert_equal('test_symbol', Factbase::ToString.new(['test_symbol']).evaluate(fact, [], Factbase.new))
  end

  def test_in_query_matching_string
    fb = Factbase.new
    fb.insert.id = 100
    assert_equal(1, fb.query('(eq "100" (to_string id))').each.to_a.size)
  end

  def test_asserts_arguments_count
    assert_raises(StandardError) do
      Factbase::ToString.new([]).evaluate(fact, [], Factbase.new)
    end
  end

  def test_rejects_a_property_with_many_values
    t = Factbase::ToString.new([:foo])
    e =
      assert_raises(ArgumentError) do
        t.evaluate(fact('foo' => [1, 2]), [], Factbase.new)
      end
    assert_includes(e.message, 'Too many values at first position, one expected', e.message)
  end
end
