# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'decoor'
require_relative '../factbase'
require_relative 'taped'

# A lazy extension of Taped that defers copying of the original maps until the first
# modification occurs. This optimizes read-only transactions and rollbacks
# on large factbases by avoiding unnecessary deep copies.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::LazyTaped < Factbase::Taped
  # Constructor.
  # @param [Array] original The original maps to wrap
  # @param [LazyTaped] root The root LazyTaped instance (nil if this is the root)
  def initialize(original, root: nil)
    @original = original
    @root = root
    if root.nil?
      # This is the root instance - owns the lazy copy state
      @copied = false
      @pairs = {}
      @original_to_copy = {}
    end
    super([], inserted: root_inserted, deleted: root_deleted, added: root_added)
  end

  # Returns true if the copy has been made (i.e., a modification occurred).
  def copied?
    root_instance.instance_variable_get(:@copied)
  end

  # Returns the pairs mapping (copy_oid -> original_oid) for reconciliation.
  def pairs
    root_instance.instance_variable_get(:@pairs)
  end

  def find_by_object_id(oid)
    return nil unless copied?
    @origin.find { |m| m.object_id == oid } ||
      root_instance.instance_variable_get(:@origin).find { |m| m.object_id == oid }
  end

  def size
    if copied? && root?
      @origin.size
    else
      @original.size
    end
  end

  def empty?
    if copied? && root?
      @origin.empty?
    else
      @original.empty?
    end
  end

  def <<(map)
    ensure_copied!
    @origin << map
    @inserted.append(map.object_id)
  end

  def each
    return to_enum(__method__) unless block_given?
    if copied?
      if root?
        # Root: iterate @origin which has copied + inserted maps
        @origin.each do |m|
          yield Factbase::Taped::TapedHash.new(m, @added)
        end
      else
        # Child: look up copied versions of @original maps
        @original.each do |m|
          copied_map = get_copied_map(m.object_id)
          # If not found, the map might already be a copied map (from index built after copy)
          copied_map ||= m if root_origin.include?(m)
          next unless copied_map
          yield Factbase::Taped::TapedHash.new(copied_map, @added)
        end
      end
    else
      @original.each do |m|
        yield LazyTapedHash.new(m, @added, self)
      end
    end
  end

  def delete_if
    ensure_copied!
    @origin.delete_if do |m|
      r = yield m
      @deleted.append(m.object_id) if r
      r
    end
  end

  def to_a
    if copied?
      if root?
        @origin.to_a
      else
        # Child: return copied versions of @original maps
        # Maps might already be copied (from index built after copy)
        @original.filter_map do |m|
          copied_map = get_copied_map(m.object_id)
          copied_map || (root_origin.include?(m) ? m : nil)
        end
      end
    else
      @original.to_a
    end
  end

  def &(other)
    return Factbase::LazyTaped.new([], root: root_instance) if other == [] || empty?
    join(other, &:&)
  end

  def |(other)
    return Factbase::LazyTaped.new(to_a, root: root_instance) if other == []
    return Factbase::LazyTaped.new(other, root: root_instance) if empty?
    join(other, &:|)
  end

  # Triggers the copy if not yet done. Called by LazyTapedHash/LazyTapedArray on write.
  def ensure_copied!
    root = root_instance
    return if root.instance_variable_get(:@copied)
    root_original = root.instance_variable_get(:@original)
    root_origin = root.instance_variable_get(:@origin)
    root_pairs = root.instance_variable_get(:@pairs)
    root_original_to_copy = root.instance_variable_get(:@original_to_copy)
    root_original.each do |m|
      n = m.transform_values(&:dup)
      # rubocop:disable Lint/HashCompareByIdentity
      root_original_to_copy[m.object_id] = n
      root_pairs[n.object_id] = m.object_id
      # rubocop:enable Lint/HashCompareByIdentity
      root_origin << n
    end
    root.instance_variable_set(:@copied, true)
    # Also populate this instance's @origin if it's different from root
    sync_origin_from_root unless root.equal?(self)
  end

  # Returns the copied map for a given original object_id.
  def get_copied_map(original_oid)
    root_instance.instance_variable_get(:@original_to_copy)[original_oid]
  end

  # Decorator of Hash that defers copy until write.
  class LazyTapedHash
    decoor(:origin)

    def initialize(origin, added, lazy_taped)
      @origin = origin
      @origin_oid = origin.object_id
      @added = added
      @lazy_taped = lazy_taped
    end

    def keys
      current_map.keys
    end

    def map(&)
      current_map.map(&)
    end

    def [](key)
      v = current_map[key]
      v = LazyTapedArray.new(v, key, @origin_oid, @added, @lazy_taped) if v.is_a?(Array)
      v
    end

    def []=(key, value)
      @lazy_taped.ensure_copied!
      map = @lazy_taped.get_copied_map(@origin_oid)
      map[key] = value
      @added.append(map.object_id)
    end

    private

    def current_map
      @lazy_taped.copied? ? @lazy_taped.get_copied_map(@origin_oid) : @origin
    end
  end

  # Decorator of Array that defers copy until write.
  class LazyTapedArray
    def initialize(origin, key, map_oid, added, lazy_taped)
      @origin = origin
      @key = key
      @map_oid = map_oid
      @added = added
      @lazy_taped = lazy_taped
    end

    def each(&)
      return to_enum(__method__) unless block_given?
      current_array.each(&)
    end

    def [](idx)
      current_array[idx]
    end

    def to_a
      current_array.to_a
    end

    def any?(&)
      current_array.any?(&)
    end

    def <<(item)
      @lazy_taped.ensure_copied!
      map = @lazy_taped.get_copied_map(@map_oid)
      map[@key] << item
      @added.append(map.object_id)
    end

    def uniq!
      @lazy_taped.ensure_copied!
      map = @lazy_taped.get_copied_map(@map_oid)
      map[@key].uniq!
      @added.append(map.object_id)
    end

    private

    def current_array
      if @lazy_taped.copied?
        map = @lazy_taped.get_copied_map(@map_oid)
        map[@key]
      else
        @origin
      end
    end
  end

  private

  def root_instance
    @root || self
  end

  def root?
    @root.nil?
  end

  def root_origin
    root_instance.instance_variable_get(:@origin)
  end

  def root_inserted
    root_instance.instance_variable_get(:@inserted) || @inserted || []
  end

  def root_deleted
    root_instance.instance_variable_get(:@deleted) || @deleted || []
  end

  def root_added
    root_instance.instance_variable_get(:@added) || @added || []
  end

  def sync_origin_from_root
    # Find maps in root's @origin that correspond to our @original
    root_original_to_copy = root_instance.instance_variable_get(:@original_to_copy)
    @original.each do |m|
      # rubocop:disable Lint/HashCompareByIdentity
      copied = root_original_to_copy[m.object_id]
      # rubocop:enable Lint/HashCompareByIdentity
      @origin << copied if copied
    end
  end

  def join(other)
    n = yield to_a, other.to_a
    raise 'Cannot join with another LazyTaped' if other.is_a?(Factbase::LazyTaped)
    raise 'Can only join with array' unless other.is_a?(Array)
    Factbase::LazyTaped.new(n, root: root_instance)
  end
end
