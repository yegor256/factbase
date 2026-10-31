# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/syntax'
require_relative '../../lib/factbase/term'

require_relative '../test__helper'

# Term test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestTerm < Factbase::Test
  def test_false_matching
    refute(Factbase::Term.new(:never, []).evaluate(fact('foo' => [100]), [], Factbase.new))
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

  def test_refuses_to_call_a_private_method
    %i[p evaluate initialize].each do |op|
      msg = assert_raises(RuntimeError) do
        Factbase::Term.new(op, []).evaluate(fact, [], Factbase.new)
      end.message
      assert_includes(msg, "the term '#{op}' is not defined", msg)
    end
  end

  def test_report_other_error
    t = Factbase::Term.new(:at, [])
    msg = assert_raises(StandardError) do
      t.evaluate(fact, [], Factbase.new)
    end.message
    assert_includes(msg, 'at (at)', msg)
  end

  def test_redresses_itself
    t = Factbase::Term.new(:something, [])
    require_relative('../../lib/factbase/indexed/indexed_term')
    t.redress!(Factbase::IndexedTerm)
    require_relative('../../lib/factbase/cached/cached_term')
    t.redress!(Factbase::CachedTerm)
    assert_kind_of(Factbase::CachedTerm, t)
    refute_kind_of(Factbase::CachedTerm, Factbase::Term.new(:something, []))
  end

  def test_runs_example_from_class_docblock
    assert(
      File.readlines(File.join(__dir__, '../../lib/factbase/term.rb'))
        .grep(/^# {2}\S/).map { |line| line.delete_prefix('#  ') }.join
        .then { |code| instance_eval(code, __FILE__, __LINE__) },
      'example in the docblock of Factbase::Term does not run'
    )
  end

  def test_keeps_the_offset_of_a_time_in_to_s
    t = Time.new(2026, 10, 4, 12, 0, 0, '+03:00')
    Factbase::Term.new(:eq, [:when, t]).to_s
    assert_equal(3 * 60 * 60, t.utc_offset, 'the time of the term was moved to UTC')
  end

  def test_builds_only_the_term_of_its_operator
    Factbase::Term.new(:eq, [:foo, 42])
    assert_operator(
      GC.stat(:total_allocated_objects).then do |before|
        Factbase::Term.new(:eq, [:foo, 42])
        GC.stat(:total_allocated_objects) - before
      end,
      :<, 60,
      'a term builds the objects of operators it does not have'
    )
  end

  def test_evaluates_every_known_operator_it_is_made_with
    assert(
      Factbase::Term.new(:and, [Factbase::Term.new(:exists, [:foo]), Factbase::Term.new(:eq, [:foo, 'ёлка'])])
        .evaluate(fact('foo' => ['ёлка']), [], Factbase.new),
      'a term made of nested operators does not evaluate them'
    )
  end

  def test_refuses_an_operator_it_does_not_know
    assert_raises(StandardError, 'an unknown operator is not refused') do
      Factbase::Term.new(:never_heard_of, []).evaluate(fact, [], Factbase.new)
    end
  end

  def test_dont_call_agg_static_when_its_selector_is_traced
    refute_predicate(
      Factbase::Syntax.new('(agg (traced (exists x)) (count))').to_term, :static?,
      'agg with a traced selector is static'
    )
  end

  def test_dont_call_agg_static_when_traced_is_deep_inside
    refute_predicate(
      Factbase::Syntax.new('(agg (and (eq y 1) (not (traced (exists x)))) (count))').to_term, :static?,
      'agg with traced deep inside its selector is static'
    )
  end

  def test_dont_call_agg_static_when_its_aggregate_is_traced
    refute_predicate(
      Factbase::Syntax.new('(agg (exists x) (traced (count)))').to_term, :static?,
      'agg with a traced aggregate is static'
    )
  end

  def test_calls_agg_static_without_traced_inside
    assert_predicate(
      Factbase::Syntax.new('(agg (and (eq y 1) (exists x)) (max x))').to_term, :static?,
      'agg without traced inside is not static'
    )
  end
end
