# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/accum'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/syntax'

# Logical test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestLogical < Factbase::Test
  def test_not_matching
    t = Factbase::Term.new(:not, [Factbase::Term.new(:always, [])])
    refute(t.evaluate(fact('foo' => [100]), [], Factbase.new))
  end

  def test_not_eq_matching
    t = Factbase::Term.new(:not, [Factbase::Term.new(:eq, [:foo, 100])])
    assert(t.evaluate(fact('foo' => [42, 12, -90]), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 100), [], Factbase.new))
  end

  def test_either
    t = Factbase::Term.new(:either, [Factbase::Term.new(:at, [5, :foo]), 42])
    assert_equal([42], t.evaluate(fact('foo' => 4), [], Factbase.new))
  end

  def test_or_matching
    t = Factbase::Term.new(
      :or,
      [
        Factbase::Term.new(:eq, [:foo, 4]),
        Factbase::Term.new(:eq, [:bar, 5])
      ]
    )
    assert(t.evaluate(fact('foo' => [4]), [], Factbase.new))
    assert(t.evaluate(fact('bar' => [5]), [], Factbase.new))
    refute(t.evaluate(fact('bar' => [42]), [], Factbase.new))
  end

  def test_when_matching
    t = Factbase::Term.new(
      :when,
      [
        Factbase::Term.new(:eq, [:foo, 4]),
        Factbase::Term.new(:eq, [:bar, 5])
      ]
    )
    assert(t.evaluate(fact('foo' => 4, 'bar' => 5), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 4), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 5, 'bar' => 5), [], Factbase.new))
  end
end
