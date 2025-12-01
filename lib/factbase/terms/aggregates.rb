# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'
require_relative 'best'
# Aggregating terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Aggregates
  MAX = Factbase::Best.new { |v, b| v > b }

  def max(_fact, maps, _fb)
    assert_args(1)
    MAX.evaluate(@operands[0], maps)
  end
end
