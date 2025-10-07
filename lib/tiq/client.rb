require 'msgpack'

module Tiq
class Client < Toq::Client

    def initialize( url, options = {} )
        host, port = url.split( ':' )
        super( options.merge( host: host, port: port.to_i ) )
    end

    def method_missing( method, *args, &block )
        call( "node.#{method}", *args, &block )
    end

end

end
