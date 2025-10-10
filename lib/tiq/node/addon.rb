module Tiq

    def self.Addon( client_or_url, shortname, *args, &block )
        client = client_or_url.is_a?( Tiq::Client ) ? client_or_url : Tiq::Client.new( client_or_url )
        client.call_addon( shortname, *args, &block )
    end

    module Addon
        def self.Attach( node, shortname = nil, &block )
            node.attach_addon shortname, proc { |*arguments| block.call( *arguments ) }
        end

        def self.Dettach( node, shortname )
            node.dettach_addon shortname
        end

        extend self
    end

class Node

    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Addon

        attr_reader :node
        attr_reader :data
        attr_reader :options

        def initialize( node, payload, options = {} )
            @node    = node
            @options = options
            @data    = @node.data
            @payload = payload
        end

        def call( *aguments, &block )
            @payload.call( *aguments, &block )
        end

        # @return   [Server::node::Node]
        #   Local node.
        def node
            node.instance_eval { @node }
        end

        # Defers a blocking operation in order to avoid blocking the main Reactor loop.
        #
        # The operation will be run in its own Thread - DO NOT block forever.
        #
        # Accepts either 2 parameters (an `operation` and a `callback` or an operation
        # as a block.
        #
        # @param    [Proc]  operation
        #   Operation to defer.
        # @param    [Proc]  callback
        #   Block to call with the results of the operation.
        #
        # @param    [Block]  block
        #   Operation to defer.
        def defer( operation = nil, callback = nil, &block )
            Thread.new( *[operation, callback].compact, &block )
        end

        # Runs a block as soon as possible in the Reactor loop.
        #
        # @param    [Block] block
        def run_asap( &block )
            Raktr.global.next_tick( &block )
        end

        # @param    [Array]    list
        #
        # @return   [Raktr::Iterator]
        #   Iterator for the provided array.
        def iterator_for( list, max_concurrency = 10 )
            Raktr.global.create_iterator( list, max_concurrency )
        end

        # Connects to a node by `url`
        #
        # @param    [String]    url
        #
        # @return   [Client::node]
        def connect_to_node( url )
            @node_connections ||= {}
            @node_connections[url] ||= Tiq::Client.new( url )
        end

    end
end
end
