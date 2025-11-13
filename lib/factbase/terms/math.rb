# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'
require_relative 'compare'

# Math terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Math
  def lte(fact, maps, fb)
    Factbase::Compare.new(:<=, @operands).evaluate(fact, maps, fb)
  end
end
