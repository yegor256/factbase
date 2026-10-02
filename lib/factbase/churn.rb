# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# A churn.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::Churn
  def initialize(ins = 0, del = 0, add = 0)
    @mutex = Mutex.new
    @inserted = ins
    @deleted = del
    @added = add
  end

  def inserted
    counts[0]
  end

  def deleted
    counts[1]
  end

  def added
    counts[2]
  end

  def to_s
    ins, del, add = counts
    if [ins, del, add].all?(&:zero?)
      'nothing'
    else
      "#{ins}i/#{del}d/#{add}a"
    end
  end

  def zero?
    counts.all?(&:zero?)
  end

  def to_i
    counts.sum
  end

  def append(ins, del, add)
    @mutex.synchronize do
      @inserted += ins
      @deleted += del
      @added += add
    end
  end

  def +(other)
    mine = counts
    theirs = other.counts
    Factbase::Churn.new(mine[0] + theirs[0], mine[1] + theirs[1], mine[2] + theirs[2])
  end

  protected

  # The three counters, read together under the same lock that +append+ takes.
  # @return [Array<Integer>] Inserted, deleted and added
  def counts
    @mutex.synchronize { [@inserted, @deleted, @added] }
  end
end
