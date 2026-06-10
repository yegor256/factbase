# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'unique'.
class Factbase::IndexedUnique
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  # rubocop:disable Elegant/NoNilReturn
  def predict(_maps, _fb, _params)
    nil
  end
  # rubocop:enable Elegant/NoNilReturn
end
