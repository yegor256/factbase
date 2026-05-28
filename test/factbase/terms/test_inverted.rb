# frozen_string_literal: true

require_relative '../../../lib/factbase/syntax'
require_relative '../../../lib/factbase/term'
require_relative '../../../lib/factbase/terms/inverted'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'

# Test for 'inverted' term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestInverted < Factbase::Test
  def test_inverting
    list = Factbase::Syntax.new('(inverted (always))').to_term.predict(
      [{ 'x' => [33] }, { 'x' => [54] }, { 'x' => [12] }], Factbase.new, {}
    )
    assert_equal('12 54 33', list.map { |m| m['x'].first }.join(' '))
  end
end
