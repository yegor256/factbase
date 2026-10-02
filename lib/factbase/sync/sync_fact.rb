# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'others'
require_relative '../../factbase'

# A single fact in a synchronized factbase.
#
# Every read and write of its properties takes the same monitor that
# the factbase takes, so a fact handle kept after the query or the insert
# is still safe to use from several threads.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::SyncFact
  # Ctor.
  # @param [Factbase::Fact] origin The original fact
  # @param [Monitor] monitor The monitor
  def initialize(origin, monitor)
    @origin = origin
    @monitor = monitor
  end

  def to_s
    @monitor.synchronize { @origin.to_s }
  end

  def all_properties
    @monitor.synchronize { @origin.all_properties }
  end

  others do |*args|
    @monitor.synchronize { @origin.__send__(*args) }
  end
end
