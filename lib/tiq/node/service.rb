module Tiq

class Node


    # Base class and namespace for all node services.
    #
    # # RPC accessibility
    #
    # Only PUBLIC methods YOU have defined will be accessible over RPC.
    #
    # # Blocking operations
    #
    # Please try to avoid blocking operations as they will block the main Reactor loop.
    #
    # However, if you really need to perform such operations, you can update the
    # relevant methods to expect a block and then pass the desired return value to
    # that block instead of returning it the usual way.
    #
    # This will result in the method's payload to be deferred into a Thread of its own.
    #
    # In addition, you can use the {#defer} and {#run_asap} methods is you need more
    # control over what gets deferred and general scheduling.
    #
    # # Asynchronous operations
    #
    # Methods which perform async operations should expect a block and pass their
    # results to that block instead of returning a value.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Service

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
