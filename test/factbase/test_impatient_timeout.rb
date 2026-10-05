# frozen_string_literal: true

require_relative '../../lib/factbase'
require_relative '../../lib/factbase/impatient'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../test__helper'

# Factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestImpatientTimeout < Factbase::Test
  def test_refuses_non_positive_timeout
    [0, -1, 0.0].each do |t|
      assert_raises(ArgumentError, t.to_s) { Factbase::Impatient.new(Factbase.new, timeout: t) }
    end
  end
end
