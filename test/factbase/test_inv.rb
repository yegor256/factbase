# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'
require 'loog'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/inv'
require_relative '../../lib/factbase/pre'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestInv < Factbase::Test
  def test_simple_checking
    fb =
      Factbase::Inv.new(Factbase.new) do |p, v|
        raise(StandardError, 'oops') if v.is_a?(String) && p == 'b'
      end
    f = fb.insert
    f.a = 42
    assert_raises(StandardError) do
      f.b = 'here we should crash'
    end
    f.c = 256
    assert_equal(42, f.a)
    assert_equal(1, fb.query('(always)').each.to_a.size)
  end

  def test_pre_and_inv
    fb =
      Factbase::Inv.new(Factbase.new) do |p, v|
        raise(StandardError, 'oops') if v.is_a?(String) && p == 'b'
      end
    fb =
      Factbase::Pre.new(fb) do |f|
        f.id = 42
      end
    f = fb.insert
    assert_equal(42, f.id)
  end

  def test_checks_imported_facts
    src = Factbase.new
    src.insert.b = 'here we should crash'
    fb =
      Factbase::Inv.new(Factbase.new) do |p, v|
        raise(StandardError, 'oops') if v.is_a?(String) && p == 'b'
      end
    assert_raises(StandardError) { fb.import(src.export) }
    assert_equal(0, fb.size, 'A refused fact must not be imported')
  end

  def test_refuses_a_nil_factbase
    assert_raises(ArgumentError) { Factbase::Inv.new(nil) { |_p, _v| true } }
  end

  def test_checks_through_to_a_and_map_as_well
    fb =
      Factbase::Inv.new(Factbase.new) do |p, v|
        raise(StandardError, 'b cannot be a string') if p == 'b' && v.is_a?(String)
      end
    fb.insert.a = 1
    assert_raises(StandardError) { fb.query('(exists a)').to_a.each { |f| f.b = 'hello' } }
    assert_raises(StandardError) { fb.query('(exists a)').map { |f| f.b = 'hello' } }
    assert_raises(StandardError) { fb.query('(exists a)').first.b = 'hello' }
    assert_raises(StandardError) { fb.query('(exists a)').take(1).first.b = 'hello' }
  end

  def test_checks_through_find_and_select
    fb =
      Factbase::Inv.new(Factbase.new) do |p, v|
        raise(StandardError, 'invalid value') if p == 'x' && v.negative?
      end
    fb.insert.a = 1
    assert_raises(StandardError) { fb.query('(exists a)').find { |f| f.x = -5 } }
    assert_raises(StandardError) { fb.query('(exists a)').select { |f| f.x = -10 } }
  end

  def test_refuses_a_missing_block
    assert_raises(ArgumentError) { Factbase::Inv.new(Factbase.new) }
  end
end
