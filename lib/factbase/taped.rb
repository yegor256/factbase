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
  def initialize(origin, inserted: [], deleted: [], added: [])
    @origin = origin
    @inserted = inserted
    @deleted = deleted
    @added = added
  end

  def inserted
    @inserted.uniq
  end

  def deleted
    @deleted.uniq
  end

  def added
    @added.uniq
  end

  def find_by_object_id(oid)
    @origin.find { |m| m.object_id == oid }
  end

  def size
    @origin.size
  end

  def <<(map)
    @origin << (map)
    @inserted.append(map.object_id)
  end

  def each
    return to_enum(__method__) unless block_given?
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

  def to_a
    @origin.to_a
  end

  def &(other)
    join(other, &:&)
  end

  def |(other)
    join(other, &:|)
  end

  # Decorator of Hash.
  class TapedHash
    def initialize(origin, added)
      @origin = origin
      @added = added
    end

    def keys
      @origin.keys
    end

    def map(&)
      @origin.map(&)
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

    def each(&)
      return to_enum(__method__) unless block_given?
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
      @added.append(@oid)
      @origin << (item)
    end

    def uniq!
      @added.append(@oid)
      @origin.uniq!
    end
  end

  private

  def join(other)
    n = yield @origin.to_a, other.to_a
    if other.respond_to?(:inserted)
      Factbase::Taped.new(
        n,
        inserted: @inserted | other.inserted,
        deleted: @deleted | other.deleted,
        added: @added | other.added
      )
    else
      Factbase::Taped.new(
        n,
        inserted: @inserted,
        deleted: @deleted,
        added: @added
      )
    end
  end
end
