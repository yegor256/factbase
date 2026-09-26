# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../lib/factbase/syntax'
require_relative '../test__helper'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestSyntaxDeep < Factbase::Test
  def test_reports_a_query_too_deep_to_parse
    depth = 100_000
    query = "#{'(and ' * depth}(eq foo 1)#{')' * depth}"
    assert_raises(Factbase::Syntax::Broken) { Factbase::Syntax.new(query).to_term }
  end
end
