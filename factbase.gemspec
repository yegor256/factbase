# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'English'
require_relative 'lib/factbase/version'

Gem::Specification.new do |s|
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = '>=3.0'
  s.name = 'factbase'
  s.version = Factbase::VERSION
  s.license = 'MIT'
  s.summary = 'Factbase'
  s.description =
    'A primitive in-memory collection of key-value records ' \
    'known as "facts," with an ability to insert facts, add properties ' \
    'to facts, and delete facts. There is no ability to modify facts. ' \
    'It is also possible to find facts using Lisp-alike query predicates. ' \
    'An entire factbase may be exported to a binary file and imported back.'
  s.authors = ['Yegor Bugayenko']
  s.email = 'yegor256@gmail.com'
  s.homepage = 'https://github.com/yegor256/factbase.rb'
  s.files = `git ls-files`.split($RS)
  s.rdoc_options = ['--charset=UTF-8']
  s.extra_rdoc_files = ['README.md', 'LICENSE.txt']
  s.add_dependency 'backtrace', '~>0.4'
  s.add_dependency 'decoor', '~>0.0'
  s.add_dependency 'ellipsized', '~>0.3'
  s.add_dependency 'json', '~>2.7'
  s.add_dependency 'logger', '~>1.0'
  s.add_dependency 'loog', '~>0.6'
  s.add_dependency 'nokogiri', '~>1.10'
  s.add_dependency 'others', '~>0.0'
  s.add_dependency 'tago', '~>0.0'
  s.add_dependency 'yaml', '~>0.3'
  s.metadata['rubygems_mfa_required'] = 'true'
end
