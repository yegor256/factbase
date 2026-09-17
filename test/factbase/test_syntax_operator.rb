# frozen_string_literal: true

require_relative '../../lib/factbase/syntax'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestSyntaxOperator < Factbase::Test
  def test_refuses_a_literal_as_operator
    e = assert_raises(Factbase::Syntax::Broken) { Factbase::Syntax.new('(42 foo)').to_term }
    assert_match(/A term name is expected/, e.message)
    assert_match(/42/, e.message)
  end

  def test_names_the_nested_bracket
    assert_match(
      /an opening bracket found/, assert_raises(Factbase::Syntax::Broken) do
                                    Factbase::Syntax.new('((eq foo 1))').to_term
                                  end.message
    )
  end
end
