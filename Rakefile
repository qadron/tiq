=begin

    This file is part of the tiq project and may be subject to
    redistribution and commercial restrictions. Please see the tiq
    web site for more information on licensing and terms of use.

=end

require 'rubygems'
require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/tiq/version'

begin
    require 'rspec'
    require 'rspec/core/rake_task'

    RSpec::Core::RakeTask.new
rescue
end

task default: [ :build, :spec ]

desc 'Generate docs'
task :docs do
    outdir = "../tiq"
    sh "rm -rf #{outdir}"
    sh "mkdir -p #{outdir}"

    sh "yardoc -o #{outdir}"

    sh "rm -rf .yardoc"
end

desc 'Clean up'
task :clean do
    sh 'rm *.gem || true'
end

desc 'Build the tiq gem.'
task build: [ :clean ] do
    sh 'gem build tiq.gemspec'
end

desc 'Build and install the tiq gem.'
task install: [ :build ] do
    sh "gem install tiq-#{Tiq::VERSION}.gem"
end

desc 'Push a new version to Rubygems'
task publish: [ :build ] do
    sh "git tag -a v#{Tiq::VERSION} -m 'Version #{Tiq::VERSION}'"
    sh "gem push tiq-#{Tiq::VERSION}.gem"
end
task release: [ :publish ]
