# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require 'time'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/query'
require_relative '../../lib/factbase/cached/cached_factbase'
require_relative '../../lib/factbase/indexed/indexed_factbase'

# Query test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestQuery < Factbase::Test
  def test_simple_parsing
    maps = []
    maps << { 'foo' => [42] }
    q = Factbase::Query.new(maps, '(eq foo 42)', Factbase.new)
    assert_equal(
      1,
      q.each do |f|
        assert_equal(42, f.foo)
      end
    )
  end

  def test_complex_parsing
    maps = [
      { 'num' => [42], 'name' => ['Jeff'] },
      { 'pi' => [3.14], 'num' => [42, 66, 0], 'name' => ['peter'] },
      { 'time' => [Time.now - 100], 'num' => [0], 'hi' => [4], 'nome' => ['Walter'] }
    ]
    {
      '(eq num 444)' => 0,
      '(eq hi 4)' => 1,
      '(eq time 0)' => 0,
      '(gt num 60)' => 1,
      '(gt hi 3)' => 1,
      "(and (lt pi 100) \n\n (gt num 1000))" => 0,
      '(exists pi)' => 1,
      '(eq pi +3.14)' => 1,
      '(not (exists hello))' => 3,
      '(eq "Integer" (type num))' => 2,
      '(eq "Integer" (type hi))' => 1,
      '(when (eq num 0) (exists time))' => 2,
      '(unique num)' => 2,
      '(unique name)' => 2,
      '(unique pi)' => 1,
      '(many num)' => 1,
      '(one num)' => 2,
      '(nil (agg (exists hello) (min num)))' => 3,
      '(gt num (minus 1 (either (at 0 (prev num)) 0)))' => 3,
      '(and (not (many num)) (eq num (plus 21 +21)))' => 1,
      '(and (not (many num)) (eq num (minus -100 -142)))' => 1,
      '(and (one num) (eq num (times 7 6)))' => 1,
      '(and (one pi) (eq pi (div -6.28 -2)))' => 1,
      '(gt (size num) 2)' => 1,
      '(matches name "^[a-z]+$")' => 1,
      '(matches nome "^Walter$")' => 1,
      '(lt (size num) 2)' => 2,
      '(eq (size _hello) 0)' => 3,
      '(eq num pi)' => 0,
      '(absent time)' => 2,
      '(eq pi (agg (eq num 0) (sum pi)))' => 1,
      '(eq num (agg (exists oops) (count)))' => 2,
      '(lt num (agg (eq num 0) (max pi)))' => 2,
      '(eq time (min time))' => 1,
      '(and (absent time) (exists pi))' => 1,
      "(and (exists time) (not (\t\texists pi)))" => 1,
      '(undef something)' => 3,
      "(or (eq num +66) (lt time #{(Time.now - 200).utc.iso8601}))" => 1,
      '(eq 3 (agg (eq num $num) (count)))' => 1
    }.each do |q, r|
      fb = Factbase::IndexedFactbase.new(Factbase::CachedFactbase.new(Factbase.new(maps)))
      assert_equal(r, fb.query(q).each.to_a.size, q)
      fb.txn do |fbt|
        assert_equal(r, fbt.query(q).each.to_a.size, q)
      end
    end
  end

  def test_simple_parsing_with_time
    maps = []
    now = Time.now.utc
    maps << { 'foo' => [now] }
    q = Factbase::Query.new(maps, "(eq foo #{now.iso8601})", Factbase.new)
    assert_equal(1, q.each.to_a.size)
  end

  def test_simple_deleting
    maps = [
      { 'foo' => [42] },
      { 'bar' => [4, 5] },
      { 'bar' => [5] }
    ]
    q = Factbase::Query.new(maps, '(eq bar 5)', Factbase.new)
    assert_equal(2, q.delete!)
    assert_equal(1, maps.size)
  end

  def test_reading_one
    maps = [
      { 'foo' => [42] },
      { 'bar' => [4, 5] }
    ]
    {
      '(agg (exists foo) (first foo))' => [42],
      '(agg (exists z) (first z))' => nil,
      '(agg (always) (count))' => 2,
      '(agg (eq bar $v) (count))' => 1,
      '(agg (eq z 40) (count))' => 0
    }.each do |q, expected|
      result = Factbase::Query.new(maps, q, Factbase.new).one(Factbase.new, v: 4)
      if expected.nil?
        assert_nil(result, "#{q} -> nil")
      else
        assert_equal(expected, result, "#{q} -> #{expected}")
      end
    end
  end

  def test_deleting_nothing
    maps = [
      { 'foo' => [42] },
      { 'bar' => [4, 5] },
      { 'bar' => [5] }
    ]
    q = Factbase::Query.new(maps, '(never)', Factbase.new)
    assert_equal(0, q.delete!)
    assert_equal(3, maps.size)
  end

  def test_to_array
    maps = []
    maps << { 'foo' => [42] }
    assert_equal(1, Factbase::Query.new(maps, '(eq foo 42)', Factbase.new).each.to_a.size)
  end

  def test_returns_int
    maps = []
    maps << { 'foo' => [1] }
    q = Factbase::Query.new(maps, '(eq foo 1)', Factbase.new)
    assert_equal(1, q.each(&:to_s))
  end

  def test_with_aliases
    maps = []
    maps << { 'foo' => [42] }
    assert_equal(45, Factbase::Query.new(maps, '(as bar (plus foo 3))', Factbase.new).each.to_a[0].bar)
    assert_equal(1, maps[0].size)
  end

  def test_with_params
    maps = [
      { 'foo' => [42] },
      { 'foo' => [17] }
    ]
    found = 0
    Factbase::Query.new(maps, '(eq foo $bar)', Factbase.new).each(bar: [42]) do
      found += 1
    end
    assert_equal(1, found)
    assert_equal(1, Factbase::Query.new(maps, '(eq foo $bar)', Factbase.new).each(bar: 42).to_a.size)
    assert_equal(0, Factbase::Query.new(maps, '(eq foo $bar)', Factbase.new).each(bar: 555).to_a.size)
  end

  def test_with_nil_alias
    maps = [{ 'foo' => [42] }]
    assert_nil(Factbase::Query.new(maps, '(as bar (plus xxx 3))', Factbase.new).each.to_a[0]['bar'])
  end

  def test_get_all_properties
    maps = [{ 'foo' => [42] }]
    f = Factbase::Query.new(maps, '(always)', Factbase.new).each.to_a[0]
    assert_includes(f.all_properties, 'foo')
  end
end
