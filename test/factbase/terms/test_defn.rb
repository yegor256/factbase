# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'

# Defn test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestDefn < Factbase::Test
  def test_defn_simple
    t = Factbase::Term.new(:defn, [:foo, 'self.to_s'])
    assert(t.evaluate(fact('foo' => 4), [], Factbase.new))
    t1 = Factbase::Term.new(:foo, ['hello, world!'])
    assert_equal('(foo \'hello, world!\')', t1.evaluate(fact, [], Factbase.new))
  end

  def test_defn_again_by_mistake
    t = Factbase::Term.new(:defn, [:and, 'self.to_s'])
    assert_raises(StandardError) do
      t.evaluate(fact, [], Factbase.new)
    end
  end

  def test_defn_bad_name_by_mistake
    t = Factbase::Term.new(:defn, [:to_s, 'self.to_s'])
    assert_raises(StandardError) do
      t.evaluate(fact, [], Factbase.new)
    end
  end

  def test_defn_bad_name_spelling_by_mistake
    t = Factbase::Term.new(:defn, [:'some-key', 'self.to_s'])
    assert_raises(StandardError) do
      t.evaluate(fact, [], Factbase.new)
    end
  end

  def test_undef_simple
    t = Factbase::Term.new(:defn, [:hello, 'self.to_s'])
    assert(t.evaluate(fact, [], Factbase.new))
    t = Factbase::Term.new(:undef, [:hello])
    assert(t.evaluate(fact, [], Factbase.new))
  end
end
