# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'tago'
require_relative '../../factbase'
require_relative '../indexed/indexed_eq'
require_relative '../indexed/indexed_one'
require_relative '../indexed/indexed_exists'
require_relative '../indexed/indexed_absent'

# Term with an index.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::IndexedTerm
  # Reduces the provided list of facts (maps) to a smaller array, if it's possible.
  #
  # NIL must be returned if indexing is prohibited in this case.
  #
  # @param [Array<Hash>] maps Array of facts
  # @param [Hash] params Key/value params to use
  # @return [Array<Hash>|nil] Returns a new array, or NIL if the original array must be used
  # @todo #249:30min Improve prediction for 'unique' term. Current prediction is quite naive and
  #  returns many false positives because it just filters facts which have exactly the same set
  #  of keys regardless the values. We should introduce more smart prediction.
  def predict(maps, fb, params)
    if @terms.key?(@op)
      t = @terms[@op]
      return t.predict(maps, fb, params) if t.respond_to?(:predict)
    end
    m = :"#{@op}_predict"
    return send(m, maps, fb, params) if respond_to?(m)
    _init_indexes until @indexes
    if @indexes.key?(@op)
      index = @indexes[@op]
      return index.predict(maps, fb, params)
    end
    key = [maps.object_id, @operands.first, @op]
    case @op
    when :gt
      if @operands.first.is_a?(Symbol) && _scalar?(@operands[1])
        prop = @operands.first.to_s
        cache_key = [maps.object_id, @operands.first, :sorted]
        if @idx[cache_key].nil?
          @idx[cache_key] = []
          maps.to_a.each do |m|
            values = m[prop]
            next if values.nil?
            values.each do |v|
              @idx[cache_key] << [v, m]
            end
          end
          @idx[cache_key].sort_by! { |pair| pair[0] }
        end
        threshold = @operands[1].is_a?(Symbol) ? params[@operands[1].to_s]&.first : @operands[1]
        return nil if threshold.nil?
        i = @idx[cache_key].bsearch_index { |pair| pair[0] > threshold } || @idx[cache_key].size
        result = @idx[cache_key][i..].map { |pair| pair[1] }.uniq
        (maps & []) | result
      end
    when :lt
      if @operands.first.is_a?(Symbol) && _scalar?(@operands[1])
        prop = @operands.first.to_s
        cache_key = [maps.object_id, @operands.first, :sorted]
        if @idx[cache_key].nil?
          @idx[cache_key] = []
          maps.to_a.each do |m|
            values = m[prop]
            next if values.nil?
            values.each do |v|
              @idx[cache_key] << [v, m]
            end
          end
          @idx[cache_key].sort_by! { |pair| pair[0] }
        end
        threshold = @operands[1].is_a?(Symbol) ? params[@operands[1].to_s]&.first : @operands[1]
        return nil if threshold.nil?
        i = @idx[cache_key].bsearch_index { |pair| pair[0] >= threshold } || @idx[cache_key].size
        result = @idx[cache_key][0...i].map { |pair| pair[1] }.uniq
        (maps & []) | result
      end
    when :and
      r = nil
      if @operands.all? { |o| o.op == :eq } && @operands.size > 1 \
        && @operands.all? { |o| o.operands.first.is_a?(Symbol) && _scalar?(o.operands[1]) }
        props = @operands.map { |o| o.operands.first }.sort
        key = [maps.object_id, props, :multi_and_eq]
        if @idx[key].nil?
          @idx[key] = {}
          maps.to_a.each do |m|
            _all_tuples(m, props).each do |t|
              @idx[key][t] = [] if @idx[key][t].nil?
              @idx[key][t].append(m)
            end
          end
        end
        tuples = Enumerator.product(
          *@operands.sort_by { |o| o.operands.first }.map do |o|
            if o.operands[1].is_a?(Symbol)
              params[o.operands[1].to_s] || []
            else
              [o.operands[1]]
            end
          end
        )
        j = tuples.map { |t| @idx[key][t] || [] }.reduce(&:|)
        r = (maps & []) | j
      else
        @operands.each do |o|
          n = o.predict(maps, fb, params)
          break if n.nil?
          if r.nil?
            r = n
          elsif n.size < r.size * 8 # to skip some obvious matchings
            r &= n.to_a
          end
          break if r.size < maps.size / 32 # it's already small enough
          break if r.size < 128 # it's obviously already small enough
        end
      end
      r
    when :or
      r = nil
      @operands.each do |o|
        n = o.predict(maps, fb, params)
        if n.nil?
          r = nil
          break
        end
        r = maps & [] if r.nil?
        r |= n.to_a
        return maps if r.size > maps.size / 4 # it's big enough already
      end
      r
    when :not
      if @idx[key].nil?
        yes = @operands.first.predict(maps, fb, params)
        if yes.nil?
          @idx[key] = { r: nil }
        else
          yes = yes.to_a.to_set
          @idx[key] = { r: maps.to_a.reject { |m| yes.include?(m) } }
        end
      end
      r = @idx[key][:r]
      if r.nil?
        nil
      else
        (maps & []) | r
      end
    when :unique
      if @idx[key].nil?
        props = @operands.map(&:to_s)
        @idx[key] = maps.to_a.select { |m| props.all? { |p| !m[p].nil? } }
      end
      (maps & []) | @idx[key]
    end
  end

  private

  def _all_tuples(fact, props)
    prop = props.first.to_s
    tuples = []
    tuples += (fact[prop] || []).zip
    if props.size > 1
      tails = _all_tuples(fact, props[1..])
      ext = []
      tuples.each do |t|
        tails.each do |tail|
          ext << (t + tail)
        end
      end
      tuples = ext
    end
    tuples
  end

  def _scalar?(item)
    item.is_a?(String) || item.is_a?(Time) || item.is_a?(Integer) || item.is_a?(Float) || item.is_a?(Symbol)
  end

  def _init_indexes
    @indexes = {
      eq: Factbase::IndexedEq.new(self, @idx),
      one: Factbase::IndexedOne.new(self, @idx),
      exists: Factbase::IndexedExists.new(self, @idx),
      absent: Factbase::IndexedAbsent.new(self, @idx)
    }
  end
end
