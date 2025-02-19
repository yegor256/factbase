# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative '../../../lib/factbase/term'

# Defn test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestDefn < Minitest::Test
  def test_defn_simple
    t = Factbase::Term.new(Factbase.new, :defn, [:foo, 'self.to_s'])
    assert(t.evaluate(fact('foo' => 4), []))
    t1 = Factbase::Term.new(Factbase.new, :foo, ['hello, world!'])
    assert_equal('(foo \'hello, world!\')', t1.evaluate(fact, []))
  end

  def test_defn_again_by_mistake
    t = Factbase::Term.new(Factbase.new, :defn, [:and, 'self.to_s'])
    assert_raises(StandardError) do
      t.evaluate(fact, [])
    end
  end

  def test_defn_bad_name_by_mistake
    t = Factbase::Term.new(Factbase.new, :defn, [:to_s, 'self.to_s'])
    assert_raises(StandardError) do
      t.evaluate(fact, [])
    end
  end

  def test_defn_bad_name_spelling_by_mistake
    t = Factbase::Term.new(Factbase.new, :defn, [:'some-key', 'self.to_s'])
    assert_raises(StandardError) do
      t.evaluate(fact, [])
    end
  end

  def test_undef_simple
    t = Factbase::Term.new(Factbase.new, :defn, [:hello, 'self.to_s'])
    assert(t.evaluate(fact, []))
    t = Factbase::Term.new(Factbase.new, :undef, [:hello])
    assert(t.evaluate(fact, []))
  end
end
