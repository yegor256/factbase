# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Indexed term 'not'.
class Factbase::IndexedNot
  def initialize(term, idx)
    @term = term
    @idx = idx
  end

  def predict(maps, fb, params)
    sub = @term.operands.first
    return unless _exact?(sub)
    key = [maps.object_id, sub, @term.op, snapshot(params)]
    @idx[key] ||= { facts: nil, count: 0, yes_set: nil }
    entry = @idx[key]
    _feed(maps.to_a, entry) do
      sub.predict(maps, fb, params)
    end
    return if entry[:facts].nil?
    maps.respond_to?(:repack) ? maps.repack(entry[:facts]) : entry[:facts]
  end

  private

  # Is the prediction of this sub-term exact?
  #
  # A prediction may answer with more facts than actually match, since the
  # query evaluates the term on every candidate afterwards. For +not+ that
  # is not recoverable: a fact the sub-term over-approximated into the set
  # is dropped from the answer and never evaluated. Only +eq+ over a
  # property and a single value is known to predict exactly.
  #
  # @param [Object] sub The only operand of +not+
  # @return [Boolean] TRUE if its prediction can be trusted as exact
  def _exact?(sub)
    return false unless sub.is_a?(Factbase::Term)
    return false unless sub.op == :eq
    ops = sub.operands
    ops.size == 2 && ops[0].is_a?(Symbol) && !ops[0].to_s.start_with?('$') && !ops[1].is_a?(Factbase::Term)
  end

  def snapshot(params)
    return params.to_a.sort_by { |pair| pair[0].to_s } if params.is_a?(Hash)
    return params unless params.respond_to?(:all_properties)
    keys = params.all_properties.sort
    keys.map { |k| [k, params["$#{k}"]] }
  end

  def _feed(facts, entry)
    return unless entry[:count] < facts.size
    yes = yield
    if yes.nil?
      entry[:facts] = nil
      entry[:yes_set] = nil
    else
      yes_set = yes.to_a.to_set
      entry[:yes_set] = yes_set
      entry[:facts] = facts.reject { |m| yes_set.include?(m) }
    end
    entry[:count] = facts.size
  end
end
