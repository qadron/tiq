require 'msgpack'
require 'toq'

module Tiq
class Client < Toq::Client

    def initialize( url, options = {} )
        options = options.symbolize_keys
        @serializer = options[:serializer] || YAML
        @handler    = (options[:handler] || 'node').to_s

        host, port = url.split( ':' )
        super( options.merge( host: host, port: port.to_i, serializer: @serializer ) )
    end

    def method_missing( method, *args, &block )
        call( "#{@handler}.#{method}", *args, &block )
    end

end

end
