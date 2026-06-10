# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/defn'
require_relative '../../../lib/factbase/terms/undef'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for defn term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestDefn < Factbase::Test
  def setup
    super
    @defn_name = :_defn_teardown
    Factbase::Undef.new([@defn_name]).evaluate(fact, [], Factbase.new)
  end

  def teardown
    Factbase::Undef.new([@defn_name]).evaluate(fact, [], Factbase.new)
    super
  end

  def test_defn_simple
    assert(Factbase::Defn.new([:foo, 'self.to_s']).evaluate(fact('foo' => 4), [], Factbase.new))
    assert_equal(
      '(foo \'hello, world!\')',
      Factbase::Term.new(:foo, ['hello, world!']).evaluate(fact, [], Factbase.new)
    )
  end

  def test_defn_again_by_mistake
    t = Factbase::Defn.new([:unexisting_function, 'self.to_s'])
    t.evaluate(fact, [], Factbase.new)
    assert_raises(StandardError) do
      t.evaluate(fact, [], Factbase.new)
    end
  end

  def test_defn_bad_name_by_mistake
    t = Factbase::Defn.new([:to_s, 'self.to_s'])
    assert_raises(StandardError) do
      t.evaluate(fact, [], Factbase.new)
    end
  end

  def test_defn_bad_name_spelling_by_mistake
    t = Factbase::Defn.new([:'some-key', 'self.to_s'])
    assert_raises(StandardError) do
      t.evaluate(fact, [], Factbase.new)
    end
  end

  def test_defn_bad_name_with_digits
    assert_raises(StandardError) do
      Factbase::Defn.new([:'123abc', 'true']).evaluate(fact, [], Factbase.new)
    end
  end

  def test_defn_bad_name_with_caps
    assert_raises(StandardError) do
      Factbase::Defn.new([:FooBar, 'true']).evaluate(fact, [], Factbase.new)
    end
  end

  def test_defn_eval_arbitrary_code
    n = :_defn_eval_z
    Factbase::Undef.new([n]).evaluate(fact, [], Factbase.new)
    Factbase::Defn.new([n, '42']).evaluate(fact, [], Factbase.new)
    assert_equal(42, Factbase::Term.new(n, []).evaluate(fact, [], Factbase.new))
  end

  def test_defn_undef_then_use
    n = @defn_name
    Factbase::Defn.new([n, 'true']).evaluate(fact, [], Factbase.new)
    Factbase::Undef.new([n]).evaluate(fact, [], Factbase.new)
    assert_raises(RuntimeError) do
      Factbase::Term.new(n, []).evaluate(fact, [], Factbase.new)
    end
  end

  def test_defn_non_symbol_argument
    assert_raises(ArgumentError) do
      Factbase::Defn.new(%w[string_name true]).evaluate(fact, [], Factbase.new)
    end
  end
end
