module Tiq
class Node
class Data

    CONCURRENCY = 20

    def initialize( node )
        @hash = {}

        @on_set_cb    = {}
        @on_delete_cb = {}

        @node = node
    end

    def update( data )
        @hash.merge! data
        nil
    end

    def get( k )
        @hash[sanitize_key( k )]
    end

    def set( k, v, broadcast = true, &block )
        k = sanitize_key( k )

        if @hash[k] == v
            block.call if block_given?
            return
        end

        # p "#{@node} set #{k} #{v} 1"

        @hash[k] = v
        call_on_set( k, v )

        if broadcast
            each_peer do |peer, iterator|
                peer.set( k, v, false ) { iterator.next }
            end
        end

        block.call if block_given?
        nil
    end

    def delete( k, broadcast = true, &block )
        k = sanitize_key( k )

        if !@hash.include? k
            block.call if block_given?
            return
        end

        @hash.delete( k )
        call_on_delete( k )

        if broadcast
            each_peer do |peer, iterator|
                peer.delete( k, false ) { iterator.next }
            end
        end

        block.call if block_given?
        nil
    end

    def on_set( k, &block )
        # p "#{@node} on_set #{k} 0 #{block}"
        (@on_set_cb[sanitize_key( k )] ||= []) << block
        nil
    end

    def on_delete( k, &block )
        (@on_delete_cb ||= []) << block
        nil
    end

    def to_h
        @hash.dup
    end

    # private

    def call_on_set( k, v, broadcast = true )
        k = sanitize_key( k )

        # p "#{@node} call_on_set #{k} 2"
        # p @on_set_cb
        # p "--- PEERS #{@node.peers}"

        if @on_set_cb[k]
            @on_set_cb[k].each do |cb|
                cb.call v
            end
        end

        if broadcast
            each_peer do |peer, iterator|
                peer.call_on_set( k, v, false ) { iterator.next }
            end
        end


        nil
    end

    def call_on_delete( k )
        k = sanitize_key( k )
        return if !@on_delete_cb[k]

        @on_delete_cb[k].each do |cb|
            cb.call
        end

        nil
    end

    def each_peer( &block )
        each  = proc do |url, iterator|
            block.call connect_to_peer( url ), iterator
        end
        @node.reactor.create_iterator( @node.peers, CONCURRENCY ).each( each )
    end

    def connect_to_peer( url, options = {} )
        @rpc_clients      ||= {}
        @rpc_clients[url] ||= Tiq::Channel.new( url, options )
    end

    def sanitize_key( k )
        k.to_s
    end

end

end
end
