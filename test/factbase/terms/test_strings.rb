# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'

# Strings test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestStrings < Factbase::Test
  def test_regexp_matching
    t = Factbase::Term.new(:matches, [:foo, '[a-z]+'])
    assert(t.evaluate(fact('foo' => 'hello'), [], Factbase.new))
    assert(t.evaluate(fact('foo' => 'hello 42'), [], Factbase.new))
    refute(t.evaluate(fact('foo' => 42), [], Factbase.new))
  end

  def test_concat
    t = Factbase::Term.new(:concat, [42, 'hi', 3.14, :hey, Time.now])
    s = t.evaluate(fact, [])
    assert(s.start_with?('42hi3.14'))
  end

  def test_concat_empty
    t = Factbase::Term.new(:concat, [])
    assert_equal('', t.evaluate(fact, [], Factbase.new))
  end

  def test_sprintf
    t = Factbase::Term.new(:sprintf, ['hi, %s!', 'Jeff'])
    assert_equal('hi, Jeff!', t.evaluate(fact, [], Factbase.new))
  end
end
