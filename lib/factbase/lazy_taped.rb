# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../factbase'
require_relative 'lazy_taped_hash'
require_relative 'taped'

# A lazy decorator of an Array with HashMaps that defers copying until modification.
class Factbase::LazyTaped
  def initialize(origin)
    @origin = origin
    @staged = []
    @copied = false
    @copies = {}.compare_by_identity
    @sources = {}.compare_by_identity
    @inserted = []
    @deleted = []
    @added = []
  end

  # Returns the original map this copy was derived from.
  # Returns nil if the base hasn't been copied yet, and the map itself
  # if it was inserted in the transaction.
  def source_of(copy)
    return unless @copied
    @sources[copy]
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

  def [](pos)
    return @staged[pos] if copied?
    pos += size if pos.negative?
    return if pos.negative?
    return @origin[pos] if pos < @origin.size
    @staged[pos - @origin.size]
  end

  def <<(map)
    @staged << map
    _track(map, map)
    @inserted.append(map.object_id)
  end

  def each
    return to_enum(__method__) unless block_given?
    yielded_size = 0
    is_copied = copied?
    unless is_copied
      @origin.each do |m|
        yield(_tape(m))
        yielded_size += 1
      end
    end
    staged =
      if is_copied
        @staged.dup
      elsif copied?
        @staged[yielded_size..]
      else
        @staged
      end
    staged&.each do |f|
      next if f.nil?
      yield(_tape(f))
    end
  end

  def delete_if
    ensure_copied!
    @staged.delete_if do |m|
      r = yield(m)
      @deleted.append(source_of(m).object_id) if r
      r
    end
  end

  def to_a
    (copied? ? @staged : (@origin + @staged)).to_a
  end

  def repack(other)
    ensure_copied!
    Factbase::Taped.new(other.map { |o| @copies[o] || o }, inserted: @inserted, deleted: @deleted, added: @added)
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
    @staged = @origin.map do |o|
      o.transform_values(&:dup).tap { |c| _track(c, o) }
    end.concat(@staged)
    @copied = true
  end

  def get_copied_map(original_map)
    return installed(original_map) if @maps
    ensure_copied!
    @copies[original_map] || original_map
  end

  # Tells that the transaction is over and its maps are now in +maps+.
  # From now on a write through a fact of this transaction goes to the map
  # that is really in the factbase, not to a copy that nobody reads.
  # @param [Array<Hash>] maps The maps of the factbase after the transaction
  def finish!(maps)
    @maps = maps
  end

  def finished?
    !@maps.nil?
  end

  private

  def installed(original_map)
    copy = @copies[original_map]
    return original_map if copy.nil?
    @maps.any? { |m| m.equal?(copy) } ? copy : original_map
  end

  def _join(other)
    ensure_copied!
    raise(ArgumentError, 'Cannot join with another Taped') if other.respond_to?(:inserted)
    raise(ArgumentError, 'Can only join with array') unless other.is_a?(Array)
    Factbase::Taped.new(yield(to_a, other.to_a), inserted: @inserted, deleted: @deleted, added: @added)
  end

  def _track(copy, original)
    @copies[original] = copy
    @sources[copy] = original
  end

  def _tape(map)
    return LazyTapedHash.new(map, self, @added) unless copied?
    Factbase::Taped::TapedHash.new(@copies[map] || map, @added)
  end
end
