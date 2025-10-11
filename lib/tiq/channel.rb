require 'msgpack'
require 'toq'

module Tiq
class Channel < Toq::Client

    def initialize( url, options = {} )
        host, port = url.split( ':' )
        super( options.merge( host: host, port: port.to_i ) )
    end

    def method_missing( method, *args, &block )
        call( "data.#{method}", *args, &block )
    end

end
end
