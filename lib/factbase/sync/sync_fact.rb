# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'others'
require_relative '../../factbase'

# A single fact, which is only touched while holding the monitor.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::SyncFact
  # Ctor.
  # @param [Factbase::Fact] origin The original fact
  # @param [Monitor] monitor The monitor to hold while reading or writing
  def initialize(origin, monitor)
    @origin = origin
    @monitor = monitor
  end

  def to_s
    @monitor.synchronize { @origin.to_s }
  end

  others do |*args|
    @monitor.synchronize { @origin.__send__(*args) }
  end
end
