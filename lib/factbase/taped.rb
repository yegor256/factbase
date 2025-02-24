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

  def initialize(origin, lookup: {})
    @origin = origin
    @inserted = Set.new
    @deleted = Set.new
    @added = Set.new
    @lookup = lookup
  end

  def find_by_object_id(oid)
    o = @lookup[oid]
    o = @origin.find { |m| m.object_id == oid } if o.nil?
    o
  end

  def size
    @origin.size
  end

  def <<(map)
    @origin << (map)
    # rubocop:disable Lint/HashCompareByIdentity
    @lookup[map.object_id] = map
    # rubocop:enable Lint/HashCompareByIdentity
    @inserted.add(map.object_id)
  end

  def each
    @origin.each do |m|
      # rubocop:disable Lint/HashCompareByIdentity
      @lookup[m.object_id] = m
      # rubocop:enable Lint/HashCompareByIdentity
      yield TapedHash.new(m, @added)
    end
  end

  def delete_if
    @origin.delete_if do |m|
      r = yield m
      if r
        @lookup.delete(m.object_id)
        @deleted.add(m.object_id)
      end
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
      v = TapedArray.new(v, @origin.object_id, @added) if v.respond_to?(:each)
      v
    end

    def []=(key, value)
      @origin[key] = value
      @added.add(@origin.object_id)
    end
  end

  # Decorator of Array.
  class TapedArray
    def initialize(origin, oid, added)
      @origin = origin
      @oid = oid
      @added = added
    end

    def each(&)
      @origin.each(&)
    end

    def [](key)
      @origin[key]
    end

    def to_a
      @origin.to_a
    end

    def any?(&)
      @origin.any?(&)
    end

    def <<(item)
      @added.add(@oid)
      @origin << (item)
    end

    def uniq!
      @added.add(@oid)
      @origin.uniq!
    end
  end
end
