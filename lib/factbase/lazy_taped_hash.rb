# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../factbase'
require_relative 'lazy_taped_array'

class Factbase::LazyTaped
  # Decorator of Hash that triggers copy-on-write.
  # @todo #424:30min Add dedicated unit tests for LazyTapedHash class.
  #  Currently this class is tested indirectly through LazyTaped tests.
  class LazyTapedHash
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
      @copied_map || @origin
    end

    def method_missing(method, *, &)
      current_map.send(method, *, &)
    end

    def respond_to_missing?(method, include_private = false)
      current_map.respond_to?(method, include_private)
    end
  end
end
