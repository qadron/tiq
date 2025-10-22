require 'msgpack'
require 'toq'

module Tiq
class Client < Toq::Client

    def initialize( url, options = {} )
        @handler = options[:handler] || 'node'

        host, port = url.split( ':' )
        super( options.merge( host: host, port: port.to_i ) )
    end

    def method_missing( method, *args, &block )
        call( "#{@handler}.#{method}", *args, &block )
    end

end

end
