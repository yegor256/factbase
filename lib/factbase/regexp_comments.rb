# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../factbase'

# Tracks comments and the extended mode while a regexp is scanned.
class Factbase::RegexpComments
  MODES = /\G\(\?([imxadu]*)(?:-([imxadu]*))?([):])/
  private_constant :MODES

  def initialize
    @extended = false
    @scopes = []
    @comment = nil
    @skip = 0
  end

  # Whether this character belongs to a comment or an option declaration.
  def skip?(source, position, char, outside)
    if @skip.positive?
      @skip -= 1
      return true
    end
    if @comment
      @comment = nil if (@comment == :group && char == ')') || (@comment == :line && char == "\n")
      return true
    end
    return false unless outside
    case char
    when '#'
      @comment = :line if @extended
      @extended
    when '('
      group(source, position)
    when ')'
      @extended = @scopes.pop || false
      false
    else
      false
    end
  end

  private

  def group(source, position)
    if source[position, 3] == '(?#'
      @comment = :group
      return true
    end
    flags = source.match(MODES, position)
    unless flags
      @scopes << @extended
      return false
    end
    @scopes << @extended if flags[3] == ':'
    @extended = true if flags[1].include?('x')
    @extended = false if flags[2]&.include?('x')
    @skip = flags[0].length - 1
    true
  end
end
