=begin

    This file is part of the Tiq project and may be subject to
    redistribution and commercial restrictions. Please see the Tiq
    web site for more information on licensing and terms of use.

=end

Gem::Specification.new do |s|
      require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/tiq/version'

      s.name              = 'tiq'
      s.version           = Tiq::VERSION
      s.license           = 'BSD 3-Clause'
      s.date              = Time.now.strftime('%Y-%m-%d')
      s.summary           = 'Simple RPC protocol.'
      s.homepage          = 'https://github.com/qadron/tiq'
      s.email             = 'tasos.laskos@gmail.com'
      s.authors           = [ 'Tasos Laskos' ]

      s.files             = %w(README.md Rakefile LICENSE.md CHANGELOG.md)
      s.files            += Dir.glob('lib/**/**')
      s.test_files        = Dir.glob('spec/**/**')

      s.extra_rdoc_files  = %w(README.md LICENSE.md CHANGELOG.md)
      s.rdoc_options      = ['--charset=UTF-8']

      s.description = <<description
description

      s.add_dependency "msgpack"
      s.add_dependency "toq"
end
