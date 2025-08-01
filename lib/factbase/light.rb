# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../factbase'

# A decorator of a Factbase, that forbids most of the operations.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Light
  def initialize(fb)
    @fb = fb
  end

  def size
    @fb.size
  end

  def insert
    @fb.insert
  end

  def to_term(query)
    @fb.to_term(query)
  end

  def query(query, maps = nil)
    @fb.query(query, maps)
  end
end
