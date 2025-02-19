# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative '../../../lib/factbase/term'

# Strings test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestStrings < Minitest::Test
  def test_regexp_matching
    t = Factbase::Term.new(Factbase.new, :matches, [:foo, '[a-z]+'])
    assert(t.evaluate(fact('foo' => 'hello'), []))
    assert(t.evaluate(fact('foo' => 'hello 42'), []))
    refute(t.evaluate(fact('foo' => 42), []))
  end

  def test_concat
    t = Factbase::Term.new(Factbase.new, :concat, [42, 'hi', 3.14, :hey, Time.now])
    s = t.evaluate(fact, [])
    assert(s.start_with?('42hi3.14'))
  end

  def test_concat_empty
    t = Factbase::Term.new(Factbase.new, :concat, [])
    assert_equal('', t.evaluate(fact, []))
  end

  def test_sprintf
    t = Factbase::Term.new(Factbase.new, :sprintf, ['hi, %s!', 'Jeff'])
    assert_equal('hi, Jeff!', t.evaluate(fact, []))
  end
end
