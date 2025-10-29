# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'tago'
require_relative '../../factbase'

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
  def predict(maps, fb, params)
    m = :"#{@op}_predict"
    if @terms.key?(@op)
      t = @terms[@op]
      return t.predict(maps, fb, params) if t.respond_to?(:predict)
    elsif respond_to?(m)
      return send(m, maps, fb, params)
    end
    key = [maps.object_id, @operands.first, @op]
    case @op
    when :one
      if @idx[key].nil?
        @idx[key] = []
        prop = @operands.first.to_s
        maps.to_a.each do |m|
          @idx[key].append(m) if !m[prop].nil? && m[prop].size == 1
        end
      end
      (maps & []) | @idx[key]
    when :exists
      if @idx[key].nil?
        @idx[key] = []
        prop = @operands.first.to_s
        maps.to_a.each do |m|
          @idx[key].append(m) unless m[prop].nil?
        end
      end
      (maps & []) | @idx[key]
    when :absent
      if @idx[key].nil?
        @idx[key] = []
        prop = @operands.first.to_s
        maps.to_a.each do |m|
          @idx[key].append(m) if m[prop].nil?
        end
      end
      (maps & []) | @idx[key]
    when :eq
      if @operands.first.is_a?(Symbol) && _scalar?(@operands[1])
        if @idx[key].nil?
          @idx[key] = {}
          prop = @operands.first.to_s
          maps.to_a.each do |m|
            m[prop]&.each do |v|
              @idx[key][v] = [] if @idx[key][v].nil?
              @idx[key][v].append(m)
            end
          end
        end
        vv =
          if @operands[1].is_a?(Symbol)
            params[@operands[1].to_s] || []
          else
            [@operands[1]]
          end
        if vv.empty?
          (maps & [])
        else
          j = vv.map { |v| @idx[key][v] || [] }.reduce(&:|)
          (maps & []) | j
        end
      end
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
end
