# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Fuzzing generator for Factbase.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Author:: Philip Belousov (belousovfilip@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::Fuzz
  LABELS = ['bug', 'enhancement', 'documentation', 'duplicate', 'question', 'good first issue', 'help wanted'].freeze
  AUTHORS = ['Noah Williams', 'Mason Jones', 'Rocket Man 🚀', 'Иван Иванович', '黒さん', 'Σωκράτης', 'المنطق سي'].freeze
  TITLES = ['Clean Code', 'Adding more elegance', 'Удаление статики', 'Re de Müller-Lyer', '纯代码', '✨✨✨'].freeze
  MESSAGES = [
    'Good point, thanks',
    'This is not an object, it is a data holder!',
    'Why is this method static? Please refactor.',
    'I dont like this name. It is not a noun.',
    'Please add a unit test for this change.',
    'NULL is evil, never use it here.',
    'Pure elegance! Very object-oriented.',
    'Finally, a clean decorator! Good job.',
    'Exquisite! No getters, no setters, just behavior.',
    'This PR makes me happy. It is very elegant.',
    'Исправь кодировку!',
    'デザインが悪い (Poor design)',
    'C’est magnifique! ',
    'Λογική χωρίς ',
    'المنطق سيء للغاية',
    'Este código no es elegante',
    '❤️❤️❤️'
  ].freeze

  def initialize
    @next_num = 0
    @max_comments = 10
    raise 'Not enough messages for fuzzing' if MESSAGES.size < @max_comments
  end

  def self.make(count = 1000)
    raise "Count must be positive: #{count}" if count.negative?
    fb = Factbase.new
    Factbase::Fuzz.new.feed(fb, count)
    fb
  end

  def feed(fb, count = 1)
    raise "Count must be positive: #{count}" if count.negative?
    count.times do
      pull_request(fb, @next_num += 1)
    end
  end

  private

  def pull_request(fb, idx)
    f = fb.insert
    f.number = idx
    f.ready = rand(2)
    f.cost = rand(1..32)
    f.kind = 'pull_request'
    f.author = AUTHORS.sample
    f.diff_size = rand(10..5000)
    f.state = %w[open merged closed].sample
    f.title = "#{TITLES.sample} in #{LABELS.sample}"
    f.test_coverage = rand(0.0..100.0).round(2)
    f.created_at = Time.now - rand(1..(60 * 60 * 24 * 180))
    MESSAGES.sample(idx % (@max_comments + 1)).each do |comment|
      f.comments = comment
    end
    f
  end
end
