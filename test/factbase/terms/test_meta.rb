# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'

# Meta test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestMeta < Factbase::Test
  def test_exists
    t = Factbase::Term.new(:exists, [:foo])
    assert(t.evaluate(fact('foo' => 41), [], Factbase.new))
    refute(t.evaluate(fact('bar' => 41), [], Factbase.new))
  end

  def test_absent
    t = Factbase::Term.new(:absent, [:foo])
    refute(t.evaluate(fact('foo' => 41), [], Factbase.new))
    assert(t.evaluate(fact('bar' => 41), [], Factbase.new))
  end

  def test_size
    t = Factbase::Term.new(:size, [:foo])
    assert_equal(1, t.evaluate(fact('foo' => 41), [], Factbase.new))
    assert_equal(0, t.evaluate(fact('foo' => nil), [], Factbase.new))
    assert_equal(4, t.evaluate(fact('foo' => [1, 2, 3, 4]), [], Factbase.new))
    assert_equal(0, t.evaluate(fact('foo' => []), [], Factbase.new))
    assert_equal(1, t.evaluate(fact('foo' => ''), [], Factbase.new))
  end

  def test_type
    t = Factbase::Term.new(:type, [:foo])
    assert_equal('nil', t.evaluate(fact('foo' => nil), [], Factbase.new))
    assert_equal('Integer', t.evaluate(fact('foo' => [1]), [], Factbase.new))
    assert_equal('Array', t.evaluate(fact('foo' => [1, 2]), [], Factbase.new))
    assert_equal('String', t.evaluate(fact('foo' => 'bar'), [], Factbase.new))
    assert_equal('Float', t.evaluate(fact('foo' => 2.1), [], Factbase.new))
    assert_equal('Time', t.evaluate(fact('foo' => Time.now), [], Factbase.new))
  end

  def test_nil
    t = Factbase::Term.new(:nil, [:foo])
    assert(t.evaluate(fact('foo' => nil), [], Factbase.new))
    refute(t.evaluate(fact('foo' => true), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 'bar'), [], Factbase.new))
  end

  def test_many
    t = Factbase::Term.new(:many, [:foo])
    refute(t.evaluate(fact('foo' => nil), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 1), [], Factbase.new))
    refute(t.evaluate(fact('foo' => '1234'), [], Factbase.new))
    assert(t.evaluate(fact('foo' => [1, 3, 5]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => []), [], Factbase.new))
  end

  def test_one
    t = Factbase::Term.new(:one, [:foo])
    assert(t.evaluate(fact('foo' => 1), [], Factbase.new))
    assert(t.evaluate(fact('foo' => '1234'), [], Factbase.new))
    assert(t.evaluate(fact('foo' => [1]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => nil), [], Factbase.new))
    refute(t.evaluate(fact('foo' => [1, 3, 5]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => []), [], Factbase.new))
  end
end
