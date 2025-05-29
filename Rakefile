# frozen_string_literal: true

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'tests'
  test.pattern = 'tests/e2e/run_all_tests.rb'
  test.verbose = true
end

task default: :test
