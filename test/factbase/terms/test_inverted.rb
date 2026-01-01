# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/inverted'
require_relative '../../../lib/factbase/syntax'

# Test for 'inverted' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestInverted < Factbase::Test
  def test_inverting
    maps = [
      { 'x' => [33] },
      { 'x' => [54] },
      { 'x' => [12] }
    ]
    t = Factbase::Syntax.new('(inverted (always))').to_term
    list = t.predict(maps, Factbase.new, {})
    assert_equal('12 54 33', list.map { |m| m['x'].first }.join(' '))
  end
end
