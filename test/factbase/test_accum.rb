# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/accum'
require_relative '../../lib/factbase/fact'
require_relative '../../lib/factbase/syntax'
require_relative '../../lib/factbase/term'

require_relative '../test__helper'

def global_function_for_this_test_only(foo)
  raise(foo)
end

# Accum test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestAccum < Factbase::Test
  def test_holds_props
    f = Factbase::Fact.new({})
    props = {}
    a = Factbase::Accum.new(f, props, false)
    a.foo = 42
    assert_raises(StandardError) { f.foo }
    assert_equal(42, a.foo)
    assert_equal([42], props['foo'])
  end

  def test_fetches_without_conflict_with_global_name
    assert_equal(
      2,
      Factbase::Accum.new(
        Factbase::Fact.new({ 'global_function_for_this_test_only' => [2] }), {},
        true
      ).global_function_for_this_test_only
    )
  end

  def test_passes_props
    f = Factbase::Fact.new({})
    props = {}
    a = Factbase::Accum.new(f, props, true)
    a.foo = 42
    assert_equal(42, f.foo)
    assert_equal(42, a.foo)
    assert_equal([42], props['foo'])
  end

  def test_appends_props
    f = Factbase::Fact.new({})
    f.foo = 42
    a = Factbase::Accum.new(f, {}, false)
    a.foo = 55
    assert_equal(2, a['foo'].size)
  end

  def test_keeps_insertion_order_in_both_modes
    [true, false].each do |pass|
      f = Factbase.new.insert
      f.foo = 1
      a = Factbase::Accum.new(f, {}, pass)
      a.foo = 2
      a.foo = 3
      assert_equal([1, 2, 3], a['foo'], "wrong order when pass=#{pass}")
    end
  end

  def test_empties
    assert_nil(Factbase::Accum.new(Factbase::Fact.new({}), {}, false)['foo'])
  end

  def test_prints_to_string
    f = Factbase::Fact.new({})
    Factbase::Accum.new(f, {}, true).foo = 42
    assert_equal('[ foo: [42] ]', f.to_s)
  end

  def test_keep_duplicates
    f = Factbase::Fact.new({})
    a = Factbase::Accum.new(f, {}, true)
    a.foo = 42
    a.foo = 41
    a.foo = 42
    a.foo = 42
    assert_equal([42, 41, 42, 42], f['foo'])
  end

  def test_all_properties_includes_accumulated
    a = Factbase::Accum.new(Factbase::Fact.new({ 'x' => [1] }), {}, false)
    a.y = 2
    a.z = 3
    assert_includes(a.all_properties, 'x')
    assert_includes(a.all_properties, 'y')
    assert_includes(a.all_properties, 'z')
  end

  def test_forgets_a_value_the_fact_rejected
    fb = Factbase.new
    fb.insert.foo = 1
    result = fb.query('(exists foo)').each.first
    assert_raises(ArgumentError) { result.foo = nil }
    result.foo = 2
    assert_equal(2, result.foo)
    assert_equal([1, 2], result['foo'])
  end

  def test_all_properties_lists_property_once_when_as_writes_existing_property
    fb = Factbase.new
    fb.insert.foo = 1
    fb.query('(as foo 2)').each do |f|
      assert_equal(['foo'], f.all_properties)
      assert_equal(1, f.all_properties.size)
    end
  end

  def test_all_properties_deduplicates_with_accum_and_syntax
    [true, false].each do |pass|
      f = Factbase::Fact.new({})
      f.foo = 42
      a = Factbase::Accum.new(f, {}, pass)
      Factbase::Syntax.new('(as foo 84)').to_term.evaluate(a, [], Factbase.new)
      assert_equal(['foo'], a.all_properties, "Failed when pass=#{pass}")
      refute_equal(f.all_properties + ['foo'], a.all_properties)
    end
  end

  def test_all_properties_deduplicates_with_multiple_properties
    fb = Factbase.new
    f = fb.insert
    f.foo = 1
    f.bar = 2
    f.baz = 3
    fb.query('(and (as foo 10) (as bar 20) (as qux 30))').each do |res|
      assert_equal(%w[bar baz foo qux], res.all_properties.sort)
      assert_equal(4, res.all_properties.size)
    end
  end

  def test_all_properties_with_symbols
    f = Factbase::Fact.new({})
    f.foo = 10
    f.bar = 20
    a = Factbase::Accum.new(f, {}, false)
    Factbase::Term.new(:as, [:foo, 11]).evaluate(a, [], Factbase.new)
    Factbase::Term.new(:as, [:bar, 21]).evaluate(a, [], Factbase.new)
    Factbase::Term.new(:as, [:baz, 31]).evaluate(a, [], Factbase.new)
    assert_equal(%w[bar baz foo], a.all_properties.sort)
    assert_equal(3, a.all_properties.size)
  end

  def test_all_properties_deduplicates_multiple_accumulated_properties
    f = Factbase::Fact.new({})
    f.alpha = 1
    f.beta = 2
    a = Factbase::Accum.new(f, {}, false)
    Factbase::Syntax.new('(as alpha 10)').to_term.evaluate(a, [], Factbase.new)
    Factbase::Syntax.new('(as alpha 20)').to_term.evaluate(a, [], Factbase.new)
    Factbase::Syntax.new('(as beta 30)').to_term.evaluate(a, [], Factbase.new)
    Factbase::Syntax.new('(as beta 40)').to_term.evaluate(a, [], Factbase.new)
    assert_equal(%w[alpha beta], a.all_properties.sort)
    assert_equal(1, a.all_properties.count('alpha'))
    assert_equal(1, a.all_properties.count('beta'))
  end
end
