# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../factbase'
require_relative 'taped'
require_relative 'lazy_taped_hash'

# A lazy decorator of an Array with HashMaps that defers copying until modification.
class Factbase::LazyTaped
  def initialize(origin)
    @origin = origin
    @staged = []
    @copied = false
    @copies = {}.compare_by_identity
    @inserted = []
    @deleted = []
    @added = []
  end

  # Returns the original map this copy was derived from.
  # Returns nil if the base hasn't been copied yet or if the fact is new.
  def source_of(copy)
    return nil unless @copied
    @copies.key(copy)
  end

  def copied?
    @copied
  end

  # Returns the unique object IDs of maps that were inserted (newly created).
  # This is used during transaction commit to identify new facts that need
  # to be added to the factbase.
  def inserted
    @inserted.uniq
  end

  # Returns the unique object IDs of maps that were deleted.
  # This is used during transaction commit to identify facts that need
  # to be removed from the factbase.
  def deleted
    @deleted.uniq
  end

  # Returns the unique object IDs of maps that were modified (properties added).
  # This is used during transaction commit to track the churn (number of changes).
  def added
    @added.uniq
  end

  def find_by_object_id(oid)
    r = @staged.find { |m| m.object_id == oid }
    r = @origin.find { |m| m.object_id == oid } if r.nil? && !copied?
    r
  end

  def size
    copied? ? @staged.size : (@origin.size + @staged.size)
  end

  def empty?
    copied? ? @staged.empty? : (@origin.empty? && @staged.empty?)
  end

  def <<(map)
    @staged << map
    _track(map, map)
    @inserted.append(map.object_id)
  end

  def each
    return to_enum(__method__) unless block_given?
    st_size = @staged.size
    orig_size = @origin.size
    unless copied?
      orig_size.times do |i|
        m = @origin[i]
        yield _tape(m) unless m.nil?
      end
    end
    st_size.times do |i|
      m = @staged[i]
      yield _tape(m) unless m.nil?
    end
  end

  def delete_if
    ensure_copied!
    @staged.delete_if do |m|
      r = yield m
      @deleted.append(source_of(m).object_id) if r
      r
    end
  end

  def to_a
    (copied? ? @staged : (@origin + @staged)).to_a
  end

  def repack(other)
    ensure_copied!
    copied = other.map { |o| @copies[o] || o }
    Factbase::Taped.new(copied, inserted: @inserted, deleted: @deleted, added: @added)
  end

  def &(other)
    return Factbase::Taped.new([], inserted: @inserted, deleted: @deleted, added: @added) if other == []
    return Factbase::Taped.new([], inserted: @inserted, deleted: @deleted, added: @added) if empty?
    _join(other, &:&)
  end

  def |(other)
    return Factbase::Taped.new(to_a, inserted: @inserted, deleted: @deleted, added: @added) if other == []
    return Factbase::Taped.new(other, inserted: @inserted, deleted: @deleted, added: @added) if empty?
    _join(other, &:|)
  end

  def ensure_copied!
    return if copied?
    @origin.each do |o|
      c = o.transform_values(&:dup)
      _track(c, o)
      @staged << c
    end
    @copied = true
  end

  def get_copied_map(original_map)
    ensure_copied!
    @copies[original_map] || original_map
  end

  private

  def _join(other)
    ensure_copied!
    n = yield to_a, other.to_a
    raise 'Cannot join with another Taped' if other.respond_to?(:inserted)
    raise 'Can only join with array' unless other.is_a?(Array)
    Factbase::Taped.new(n, inserted: @inserted, deleted: @deleted, added: @added)
  end

  def _track(copy, original)
    @copies[original] = copy
  end

  def _tape(map)
    return LazyTapedHash.new(map, self, @added) unless copied?
    copy = @copies[map] || map
    Factbase::Taped::TapedHash.new(copy, @added)
  end
end
