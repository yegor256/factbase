# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'others'
require_relative '../../factbase'

# A single fact in a factbase, which is sentitive to changes.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::IndexedFact
  # Ctor.
  # @param [Factbase::Fact] origin The original fact
  # @param [Hash] idx The index
  def initialize(origin, idx)
    @origin = origin
    @idx = idx
  end

  def to_s
    @origin.to_s
  end

  # When a method is missing, this method is called.
  others do |*args|
    @idx.clear if args[0].to_s.end_with?('=')
    @origin.send(*args)
  end
end
