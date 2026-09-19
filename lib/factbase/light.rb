# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../factbase'

# A decorator of a Factbase, that forbids most of the operations.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
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

  def txn
    raise(StandardError, 'A transaction cannot be started inside a transaction')
  end

  def method_missing(method, ...)
    if @fb.respond_to?(method)
      raise(
        StandardError,
        "The '#{method}' operation is not available inside a transaction, use it on the factbase itself"
      )
    end
    super
  end

  def respond_to_missing?(method, include_private = false)
    @fb.respond_to?(method, include_private) || super
  end
end
