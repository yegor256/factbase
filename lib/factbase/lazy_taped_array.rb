# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../factbase'

class Factbase::LazyTaped
  # Decorator of Array that triggers copy-on-write.
  # @todo #424:30min Add dedicated unit tests for LazyTapedArray class.
  #  Currently this class is tested indirectly through LazyTaped tests.
  #  We should add explicit tests for all public methods including each, [],
  #  to_a, any?, <<, and uniq! to ensure proper copy-on-write behavior.
  class LazyTapedArray
    def initialize(origin, key, taped_hash, added)
      @origin = origin
      @key = key
      @taped_hash = taped_hash
      @added = added
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

    def any?(pattern = nil, &)
      pattern ? current_array.any?(pattern) : current_array.any?(&)
    end

    def <<(item)
      @taped_hash.ensure_copied_map
      @added.append(@taped_hash.tracking_id)
      @taped_hash.get_copied_array(@key) << item
    end

    def uniq!
      @taped_hash.ensure_copied_map
      @added.append(@taped_hash.tracking_id)
      @taped_hash.get_copied_array(@key).uniq!
    end

    private

    def current_array
      @taped_hash.copied? ? @taped_hash.get_copied_array(@key) : @origin
    end
  end
end
