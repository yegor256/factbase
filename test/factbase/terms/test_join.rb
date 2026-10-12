# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require_relative '../../../lib/factbase/accum'
require_relative '../../../lib/factbase/syntax'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/join'
require_relative '../../test__helper'

# Test for 'as' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestJoin < Factbase::Test
  def test_join
    maps = [{ 'x' => 1, 'y' => 0, 'z' => 4 }, { 'x' => [2], 'bar' => [44, 55, 66] }]
    {
      '(join "foo_x<=x" (gt x 1))' => '(exists foo_x)',
      '(join "foo <=bar  " (exists bar))' => '(and (eq foo 44) (eq foo 55))',
      '(join "uuu" (eq x 1))' => '(absent uuu)',
      '(join "uuu <= fff" (eq fff 1))' => '(absent uuu)'
    }.each do |q, r|
      t = Factbase::Syntax.new(q).to_term
      maps.each do |m|
        f = Factbase::Accum.new(fact(m), {}, false)
        require_relative('../../../lib/factbase/logged')
        f = Factbase::Logged::Fact.new(f, log: Loog::NULL)
        next unless t.evaluate(f, maps, Factbase.new)
        assert(Factbase::Syntax.new(r).to_term.evaluate(f, [], Factbase.new), "#{q} -> #{f} doesn't match #{r}")
      end
    end
  end

  def test_rejects_mapping_with_extra_separator
    term = Factbase::Syntax.new('(join "left<=right<=unexpected" (always))').to_term
    assert_includes(
      assert_raises(RuntimeError) do
        term.evaluate(Factbase::Accum.new(fact({}), {}, false), [], Factbase.new)
      end.message,
      'left<=right<=unexpected'
    )
  end
end
