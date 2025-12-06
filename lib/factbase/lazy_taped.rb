# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../factbase'
require_relative 'taped'
require_relative 'lazy_taped_hash'

# A lazy decorator of an Array with HashMaps that defers copying until modification.
class Factbase::LazyTaped
  def initialize(origin)
    @origin = origin
    @copied = false
    @maps = nil
    @pairs = nil
    @inserted = []
    @deleted = []
    @added = []
  end

  def pairs
    return {} unless @pairs
    result = {}.compare_by_identity
    @pairs.each { |copied, original| result[copied] = original }
    result
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
    ensure_copied if @copied
    (@maps || @origin).find { |m| m.object_id == oid }
  end

  def size
    (@maps || @origin).size
  end

  def empty?
    (@maps || @origin).empty?
  end

  def <<(map)
    ensure_copied
    @maps << map
    @inserted.append(map.object_id)
  end

  def each
    return to_enum(__method__) unless block_given?
    if @copied
      @maps.each do |m|
        yield Factbase::Taped::TapedHash.new(m, @added)
      end
    else
      @origin.each do |m|
        yield LazyTapedHash.new(m, self, @added)
      end
    end
  end

  def delete_if
    ensure_copied
    @maps.delete_if do |m|
      r = yield m
      @deleted.append(@pairs[m].object_id) if r
      r
    end
  end

  def to_a
    (@maps || @origin).to_a
  end

  def &(other)
    if other == [] || (@maps || @origin).empty?
      return Factbase::Taped.new([], inserted: @inserted, deleted: @deleted, added: @added)
    end
    join(other, &:&)
  end

  def |(other)
    return Factbase::Taped.new(to_a, inserted: @inserted, deleted: @deleted, added: @added) if other == []
    if (@maps || @origin).empty?
      return Factbase::Taped.new(other, inserted: @inserted, deleted: @deleted, added: @added)
    end
    join(other, &:|)
  end

  def ensure_copied
    return if @copied
    @pairs = {}.compare_by_identity
    @maps =
      @origin.map do |m|
        n = m.transform_values(&:dup)
        @pairs[n] = m
        n
      end
    @copied = true
  end

  def get_copied_map(original_map)
    ensure_copied
    @maps.find { |m| @pairs[m].equal?(original_map) }
  end

  private

  def join(other)
    n = yield (@maps || @origin).to_a, other.to_a
    raise 'Cannot join with another Taped' if other.respond_to?(:inserted)
    raise 'Can only join with array' unless other.is_a?(Array)
    Factbase::Taped.new(
      n,
      inserted: @inserted,
      deleted: @deleted,
      added: @added
    )
  end
end
