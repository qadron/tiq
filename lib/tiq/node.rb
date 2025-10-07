require 'set'
require_relative 'node/data'
require_relative 'channel'
require_relative 'client'

module Tiq
class Node

    INTERVAL_PING = 5

    attr_reader :data
    attr_reader :reactor

    # Initializes the node by:
    #
    #   * Adding the peer (if the user has supplied one) to the peer list.
    #   * Getting the peer's peer list and appending them to its own.
    #   * Announces itself to the peer and instructs it to propagate our URL
    #     to the others.
    #
    # @param    [Cuboid::Options]    options
    def initialize( options )
        @options = options
        @url     = @options[:url]

        $stdout.puts 'Initializing node...'

        @dead_nodes = Set.new
        @peers      = Set.new
        @nodes_info_cache = []

        host, port = @url.split( ':' )
        options[:host] ||= host || 'localhost'
        options[:port] ||= port || 9999

        @server  = Toq::Server.new( host: options[:host], port: options[:port] )
        @reactor = @server.reactor
        @server.add_async_check do |method|
            # methods that expect a block are async
            method.parameters.flatten.include? :block
        end
        @server.add_handler( 'node', self )

        @reactor.run_in_thread if !@reactor.running?

        @data = Data.new( self )
        @server.add_handler( 'data', @data )

        @reactor.on_error do |_, e|
            $stderr.puts "Reactor: #{e}"

            e.backtrace.each do |l|
                $stderr.puts "Reactor: #{l}"
            end
        end

        @reactor.at_interval( @options[:ping_interval] || INTERVAL_PING ) do
            ping
            check_for_comebacks
        end

        if( peer = @options[:peer] )
            # Grab the peer's peers.
            connect_to_peer( peer ).peers do |grid_peers|
                if grid_peers.rpc_exception?
                    $stdout.puts "Peer seems dead: #{peer}"
                    $stderr.puts "Reactor: #{grid_peers}"

                    if grid_peers.backtrace
                        grid_peers.backtrace.each do |l|
                            $stderr.puts "Reactor: #{l}"
                        end
                    end

                    add_dead_peer( peer )
                    next
                end

                grid_peers << peer
                grid_peers.each { |url| add_peer url }
                announce @url
            end
        end

        $stdout.puts 'Node ready.'

        log_updated_peers

        run
    end

    # @return   [Boolean]
    #   `true` if grid member, `false` otherwise.
    def grid_member?
        @peers.any?
    end

    def unplug
        @server.create_iterator( @peers, 20 ).each do |peer, iterator|
            connect_to_peer( peer ).remove_peer( @url ) { iterator.next }
        end

        @peers.clear
        @dead_nodes.clear

        nil
    end

    # Adds a peer to the peer list.
    #
    # @param    [String]    node_url
    #   URL of a peering node.
    def add_peer( node_url )
        $stdout.puts "Adding peer: #{node_url}"
        @peers << node_url

        connect_to_peer( @peers.to_a.first ).update_data( @data.to_h )

        log_updated_peers
        true
    end

    def update_data( data )
        @data.update( data )
        nil
    end

    def remove_peer( url )
        @peers.delete url
        @dead_nodes.delete url
        nil
    end

    # @return   [Array]
    #   Peer/node/peer URLs.
    def peers
        @peers.to_a
    end

    def peers_with_info( &block )
        fail 'This method requires a block!' if !block_given?

        @peers_cmp = ''

        if @nodes_info_cache.empty? || @peers_cmp != peers.to_s
            @peers_cmp = peers.to_s

            each = proc do |peer, iter|
                connect_to_peer( peer ).info do |info|
                    if info.rpc_exception?
                        $stdout.puts "Peer seems dead: #{peer}"
                        add_dead_peer( peer )
                        log_updated_peers

                        iter.return( nil )
                    else
                        iter.return( info )
                    end
                end
            end

            after = proc do |nodes|
                @nodes_info_cache = nodes.compact
                block.call( @nodes_info_cache )
            end

            @reactor.create_iterator( peers ).map( each, after )
        else
            block.call( @nodes_info_cache )
        end
    end

    # @return    [Hash]
    #
    #   * `url` -- This node's URL.
    #   * `name` -- Nickname
    #   * `peers` -- Array of peers.
    def info
        {
          'url'               => @url,
          'name'              => @options[:name],
          'peers'             => self.peers,
          'unreachable_peers' => @dead_nodes.to_a
        }
    end

    def alive?
        true
    end

    def run
        $stdout.puts 'Running'
        @server.start
    rescue => e
        $stderr.puts e
        $stderr.puts "Could not start server"
        e.backtrace.each do |l|
            $stderr.puts l
        end

        exit 1
    end

    def shutdown
        Thread.new do
            $stdout.puts 'Shutting down...'
            @reactor.stop
        end
    end

    private

    def add_dead_peer( url )
        remove_peer( url )
        @dead_nodes << url
    end

    def log_updated_peers
        $stdout.puts 'Updated peers:'

        if !peers.empty?
            peers.each { |node| $stdout.puts( '---- ' + node ) }
        else
            $stdout.puts '<empty>'
        end
    end

    def ping
        peers.each do |peer|
            connect_to_peer( peer ).alive? do |res|
                next if !res.rpc_exception?
                add_dead_peer( peer )
                $stdout.puts "Found dead peer: #{peer} "
            end
        end
    end

    def check_for_comebacks
        @dead_nodes.dup.each do |url|
            peer = connect_to_peer( url )
            peer.alive? do |res|
                next if res.rpc_exception?

                $stdout.puts "Peer came back to life: #{url}"
                ([@url] | peers).each do |node|
                    peer.add_peer( node ){}
                end

                add_peer( url )
                @dead_nodes.delete url
            end
        end
    end

    # Announces the node to the ones in the peer list
    #
    # @param    [String]    node
    #   URL
    def announce( node )
        $stdout.puts "Announcing: #{node}"

        peers.each do |peer|
            $stdout.puts "---- to: #{peer}"
            connect_to_peer( peer ).add_peer( node ) do |res|
                add_dead_peer( peer ) if res.rpc_exception?
            end
        end
    end

    def connect_to_peer( url, options = {} )
        @rpc_clients      ||= {}
        @rpc_clients[url] ||= Tiq::Client.new( url, options )
    end
end
end
