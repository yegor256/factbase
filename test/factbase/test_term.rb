# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/term'

# Term test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestTerm < Factbase::Test
  def test_false_matching
    t = Factbase::Term.new(:never, [])
    refute(t.evaluate(fact('foo' => [100]), [], Factbase.new))
  end

  def test_size_matching
    t = Factbase::Term.new(:size, [:foo])
    assert_equal(3, t.evaluate(fact('foo' => [42, 12, -90]), [], Factbase.new))
    assert_equal(0, t.evaluate(fact('bar' => 100), [], Factbase.new))
  end

  def test_exists_matching
    t = Factbase::Term.new(:exists, [:foo])
    assert(t.evaluate(fact('foo' => [42, 12, -90]), [], Factbase.new))
    refute(t.evaluate(fact('bar' => 100), [], Factbase.new))
  end

  def test_absent_matching
    t = Factbase::Term.new(:absent, [:foo])
    assert(t.evaluate(fact('z' => [42, 12, -90]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 100), [], Factbase.new))
  end

  def test_type_matching
    t = Factbase::Term.new(:type, [:foo])
    assert_equal('Integer', t.evaluate(fact('foo' => 42), [], Factbase.new))
    assert_equal('Integer', t.evaluate(fact('foo' => [42]), [], Factbase.new))
    assert_equal('Array', t.evaluate(fact('foo' => [1, 2, 3]), [], Factbase.new))
    assert_equal('String', t.evaluate(fact('foo' => 'Hello, world!'), [], Factbase.new))
    assert_equal('Float', t.evaluate(fact('foo' => 3.14), [], Factbase.new))
    assert_equal('Time', t.evaluate(fact('foo' => Time.now), [], Factbase.new))
    assert_equal('Integer', t.evaluate(fact('foo' => 1_000_000_000_000_000), [], Factbase.new))
    assert_equal('nil', t.evaluate(fact, [], Factbase.new))
  end

  def test_past
    t = Factbase::Term.new(:prev, [:foo])
    assert_nil(t.evaluate(fact('foo' => 4), [], Factbase.new))
    assert_equal([4], t.evaluate(fact('foo' => 5), [], Factbase.new))
  end

  def test_at
    t = Factbase::Term.new(:at, [1, :foo])
    assert_nil(t.evaluate(fact('foo' => 4), [], Factbase.new))
    assert_equal(5, t.evaluate(fact('foo' => [4, 5]), [], Factbase.new))
  end

  def test_report_missing_term
    t = Factbase::Term.new(:something, [])
    msg = assert_raises(StandardError) do
      t.evaluate(fact, [], Factbase.new)
    end.message
    assert_includes(msg, 'not defined at (something)', msg)
  end

  def test_report_other_error
    t = Factbase::Term.new(:at, [])
    msg = assert_raises(StandardError) do
      t.evaluate(fact, [], Factbase.new)
    end.message
    assert_includes(msg, 'at (at)', msg)
  end
end
