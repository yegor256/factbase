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
class Factbase::CachedFact
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
        cache = fbt.instance_variable_get(:@cache)
        cache&.clear
        copy = sync(fbt, map, key) unless map.nil?
        notify(cache, copy || map, key) unless cache.nil?
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
  # @param [Hash] cache Cache of queries (to clean it on attribute addition)
  def initialize(origin, cache, **)
    @origin = origin
    @cache = cache
  end

  def to_s
    @origin.to_s
  end

  others do |*args|
    if args[0].to_s.end_with?('=')
      @cache.clear
      key = args[0].to_s.chop
      res = @origin.public_send(*args)
      map = Factbase::CachedFact.extract(@origin)
      Factbase::CachedFact.notify(@cache, map, key)
      res
    else
      @origin.public_send(*args)
    end
  end
end

class Factbase::CachedFactbase; end

# Hook into transactions of CachedFactbase.
module Factbase::CachedTxn
  def txn(&)
    return super unless block_given?
    inner = nil
    super do |fbt|
      inner = fbt
      Factbase::CachedFact.register(@cache, fbt)
      yield(fbt)
    end
  ensure
    Factbase::CachedFact.unregister(@cache, inner) unless inner.nil?
  end
end

Factbase::CachedFactbase.prepend(Factbase::CachedTxn)
