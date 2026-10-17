# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'others'
require_relative '../../factbase'

# A single fact in a factbase, which is sensitive to changes.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::IndexedFact
  @listeners = {}.compare_by_identity
  @mutex = Mutex.new

  class << self
    def register(parent, child)
      @mutex.synchronize do
        @listeners[parent] ||= []
        @listeners[parent] << child
      end
    end

    def unregister(parent, child)
      @mutex.synchronize do
        list = @listeners[parent]
        list&.delete(child)
        @listeners.delete(parent) if list && list.empty?
      end
    end

    def notify(parent, map, key)
      targets = @mutex.synchronize { @listeners[parent]&.dup }
      return if targets.nil?
      targets.each do |fbt|
        idx = fbt.instance_variable_get(:@idx)
        idx&.clear
        copy = sync(fbt, map, key) unless map.nil?
        notify(idx, copy || map, key) unless idx.nil?
      end
    end

    def extract(origin)
      obj = origin
      while obj && !obj.instance_variable_defined?(:@map)
        obj = obj.instance_variable_get(:@fact) || obj.instance_variable_get(:@origin)
      end
      obj&.instance_variable_get(:@map)
    end

    private

    def sync(fbt, map, key)
      base = fbt.instance_variable_get(:@origin)
      while base && !base.instance_variable_defined?(:@maps)
        base = base.instance_variable_get(:@origin) || base.instance_variable_get(:@fb)
      end
      taped = base&.instance_variable_get(:@maps)
      return unless taped&.instance_variable_defined?(:@copies)
      copies = taped.instance_variable_get(:@copies)
      return if copies.nil?
      copy = copies[map]
      copy[key] = map[key].dup if copy && map[key]
      copy
    end
  end

  # Ctor.
  # @param [Factbase::Fact] origin The original fact
  # @param [Hash] idx The index
  # @param [Set] fresh The shared set of fresh fact IDs
  def initialize(origin, idx, fresh)
    @origin = origin
    @idx = idx
    @fresh = fresh
  end

  def to_s
    @origin.to_s
  end

  others do |*args|
    if args[0].to_s.end_with?('=')
      @idx.clear unless @fresh.include?(object_id)
      key = args[0].to_s.chop
      res = @origin.public_send(*args)
      map = Factbase::IndexedFact.extract(@origin)
      Factbase::IndexedFact.notify(@idx, map, key)
      res
    else
      @origin.public_send(*args)
    end
  end
end

class Factbase::IndexedFactbase; end

# Hook into transactions of IndexedFactbase.
module Factbase::IndexedTxn
  def txn(&)
    return super unless block_given?
    inner = nil
    super do |fbt|
      inner = fbt
      Factbase::IndexedFact.register(@idx, fbt)
      yield(fbt)
    end
  ensure
    Factbase::IndexedFact.unregister(@idx, inner) unless inner.nil?
  end
end

Factbase::IndexedFactbase.prepend(Factbase::IndexedTxn)
