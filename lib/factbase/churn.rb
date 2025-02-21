# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# A churn.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Churn
  attr_reader :inserted, :deleted, :added

  def initialize(ins = 0, del = 0, add = 0)
    @mutex = Mutex.new
    @inserted = ins
    @deleted = del
    @added = add
  end

  def to_s
    "#{@inserted}i/#{@deleted}d/#{@added}a"
  end

  def zero?
    @inserted.zero? && @deleted.zero? && @added.zero?
  end

  def append(ins, del, add)
    @mutex.synchronize do
      @inserted += ins
      @deleted += del
      @added += add
    end
  end
end
