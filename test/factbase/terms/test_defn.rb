# frozen_string_literal: true

require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/defn'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for defn term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestDefn < Factbase::Test
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
end
