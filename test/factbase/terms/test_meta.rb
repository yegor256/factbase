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
