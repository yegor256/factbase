# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../factbase'
require_relative 'lazy_taped_array'

class Factbase::LazyTaped
  # Decorator of Hash that triggers copy-on-write.
  class LazyTapedHash
    MUTATING_METHODS = %i[
      clear
      compare_by_identity
      delete
      delete_if
      filter!
      keep_if
      merge!
      rehash
      reject!
      replace
      select!
      shift
      store
      transform_keys!
      transform_values!
      update
    ].freeze
    private_constant :MUTATING_METHODS

    # Creates a new LazyTapedHash decorator.
    # @param origin [Hash] The original hash being wrapped (not yet copied)
    # @param lazy_taped [Factbase::LazyTaped] The parent LazyTaped instance that manages copy-on-write
    # @param added [Array] Array to track object IDs of maps that have been modified
    def initialize(origin, lazy_taped, added)
      @origin = origin
      @lazy_taped = lazy_taped
      @added = added
      @copied_map = nil
    end

    def keys
      current_map.keys
    end

    def map(&)
      current_map.map(&)
    end

    def [](key)
      v = current_map[key]
      v = LazyTapedArray.new(v, key, self, @added) if v.is_a?(Array)
      v
    end

    def []=(key, value)
      ensure_copied_map
      @copied_map[key] = value
      @added.append(@copied_map.object_id)
    end

    def ensure_copied_map
      return if @copied_map
      @copied_map = @lazy_taped.get_copied_map(@origin)
    end

    def get_copied_array(key)
      ensure_copied_map
      @copied_map[key]
    end

    def tracking_id
      @copied_map ? @copied_map.object_id : @origin.object_id
    end

    def copied?
      !@copied_map.nil?
    end

    private

    def current_map
      ensure_copied_map if @lazy_taped.copied?
      @copied_map || @origin
    end

    def method_missing(method, *, &)
      mutating = method.to_s.end_with?('=', '!') || MUTATING_METHODS.include?(method)
      ensure_copied_map if mutating
      result = current_map.__send__(method, *, &)
      @added.append(@copied_map.object_id) if mutating
      result
    end

    def respond_to_missing?(method, include_private = false)
      current_map.respond_to?(method, include_private)
    end
  end
end
