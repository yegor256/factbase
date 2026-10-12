# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../factbase'

# The +each+ of a decorator that delegates through +decoor+.
#
# The +decoor+ gem always passes a block to the origin, so without this
# mixin +each+ called without a block returns whatever the origin returns
# instead of an +Enumerator+, as it does on +Factbase+.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
module Factbase::Enumerated
  # Iterate facts one by one.
  # @yield [Fact] Facts one-by-one
  # @return [Integer|Enumerator] Total number of facts, or an enumerator if no block given
  def each(&)
    return to_enum(__method__) unless block_given?
    method_missing(:each, &)
  end
end
