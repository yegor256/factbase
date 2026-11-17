# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# The identity of the list of facts an index entry belongs to.
#
# A plain array is identified by its own object, while a decorator that copies
# facts lazily in a transaction reports the array it decorates, so the index
# already built for the original keeps answering inside the transaction.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
module Factbase::Keyed
  private

  # @param [Array<Hash>] maps The list of facts an index is built for
  # @return [Integer] The identity to key the index entry by
  def the_key(maps)
    maps.respond_to?(:the_key) ? maps.the_key : maps.object_id
  end
end
