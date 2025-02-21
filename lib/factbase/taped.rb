# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../factbase'

# A decorator of an Array with HashMaps, that records facts that have been touched,
# using their +object_id+.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Taped
  attr_reader :inserted, :deleted, :added

  def initialize(origin)
    @origin = origin
    @inserted = []
    @deleted = []
    @added = []
  end

  def modified?
    !@inserted.empty? || !@deleted.empty? || !@added.empty?
  end

  def size
    @origin.size
  end

  def <<(map)
    @origin << (map)
    @inserted.append(map.object_id)
  end

  def each
    @origin.each do |m|
      yield TapedHash.new(m, @added)
    end
  end

  def delete_if
    @origin.delete_if do |m|
      r = yield m
      @deleted.append(m.object_id) if r
      r
    end
  end

  # Decorator of Hash.
  class TapedHash
    def initialize(origin, added)
      @origin = origin
      @added = added
    end

    def [](key)
      v = @origin[key]
      v = TapedArray.new(v, @origin.object_id, @added) if v.is_a?(Array)
      v
    end

    def []=(key, value)
      @origin[key] = value
      @added.append(@origin.object_id)
    end
  end

  # Decorator of Array.
  class TapedArray
    def initialize(origin, oid, added)
      @origin = origin
      @oid = oid
      @added = added
    end

    def <<(item)
      @added.append(@oid)
      @origin << (item)
    end

    def uniq!
      @added.append(@oid)
      @origin.uniq!
    end
  end
end
