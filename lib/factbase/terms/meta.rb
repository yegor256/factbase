# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Meta terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Meta
  # The property has exactly one value.
  def one(fact, maps, fb)
    assert_args(1)
    v = _values(0, fact, maps, fb)
    !v.nil? && v.size == 1
  end
end
