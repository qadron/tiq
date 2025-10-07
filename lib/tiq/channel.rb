require 'msgpack'

module Tiq
class Channel

    def initialize( url, options = {} )
        host, port = url.split( ':' )
        @client = Toq::Client.new( options.merge( host: host, port: port.to_i ) )
    end

    def method_missing( method, *args, &block )
        @client.call( "data.#{method}", *args, &block )
    end

end

end
