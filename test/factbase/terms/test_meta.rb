# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative '../../../lib/factbase/term'

# Meta test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestMeta < Minitest::Test
  def test_exists
    t = Factbase::Term.new(Factbase.new, :exists, [:foo])
    assert(t.evaluate(fact('foo' => 41), []))
    refute(t.evaluate(fact('bar' => 41), []))
  end

  def test_absent
    t = Factbase::Term.new(Factbase.new, :absent, [:foo])
    refute(t.evaluate(fact('foo' => 41), []))
    assert(t.evaluate(fact('bar' => 41), []))
  end

  def test_size
    t = Factbase::Term.new(Factbase.new, :size, [:foo])
    assert_equal(1, t.evaluate(fact('foo' => 41), []))
    assert_equal(0, t.evaluate(fact('foo' => nil), []))
    assert_equal(4, t.evaluate(fact('foo' => [1, 2, 3, 4]), []))
    assert_equal(0, t.evaluate(fact('foo' => []), []))
    assert_equal(1, t.evaluate(fact('foo' => ''), []))
  end

  def test_type
    t = Factbase::Term.new(Factbase.new, :type, [:foo])
    assert_equal('nil', t.evaluate(fact('foo' => nil), []))
    assert_equal('Integer', t.evaluate(fact('foo' => [1]), []))
    assert_equal('Array', t.evaluate(fact('foo' => [1, 2]), []))
    assert_equal('String', t.evaluate(fact('foo' => 'bar'), []))
    assert_equal('Float', t.evaluate(fact('foo' => 2.1), []))
    assert_equal('Time', t.evaluate(fact('foo' => Time.now), []))
  end

  def test_nil
    t = Factbase::Term.new(Factbase.new, :nil, [:foo])
    assert(t.evaluate(fact('foo' => nil), []))
    refute(t.evaluate(fact('foo' => true), []))
    refute(t.evaluate(fact('foo' => 'bar'), []))
  end

  def test_many
    t = Factbase::Term.new(Factbase.new, :many, [:foo])
    refute(t.evaluate(fact('foo' => nil), []))
    refute(t.evaluate(fact('foo' => 1), []))
    refute(t.evaluate(fact('foo' => '1234'), []))
    assert(t.evaluate(fact('foo' => [1, 3, 5]), []))
    refute(t.evaluate(fact('foo' => []), []))
  end

  def test_one
    t = Factbase::Term.new(Factbase.new, :one, [:foo])
    assert(t.evaluate(fact('foo' => 1), []))
    assert(t.evaluate(fact('foo' => '1234'), []))
    assert(t.evaluate(fact('foo' => [1]), []))
    refute(t.evaluate(fact('foo' => nil), []))
    refute(t.evaluate(fact('foo' => [1, 3, 5]), []))
    refute(t.evaluate(fact('foo' => []), []))
  end
end
