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
  attr_reader :cache

  def initialize(fb, cache)
    @fb = fb
    @cache = cache
  end

  def size
    @fb.size
  end

  def insert
    @fb.insert
  end

  def query(query)
    @fb.query(query)
  end
end
