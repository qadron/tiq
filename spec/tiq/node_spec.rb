require 'spec_helper'

describe Tiq::Node do
    let( :node ) { @node ||= Tiq::Node.new( url: '0.0.0.0:9999' ) }
    let( :peer ) { @peer ||= Tiq::Node.new( url: '0.0.0.0:9998', peer: '0.0.0.0:9999' ) }
    let( :node2 ) { @node2 ||= Tiq::Node.new( url: '0.0.0.0:8999' ) }

    before( :each ) do
        node.start
        peer.start
        sleep 0.1
    end

    after( :each ) do
        @peer.shutdown
        @peer = nil
        @node.shutdown
        @node = nil
        sleep 1
    end

    describe '#url' do
        it 'returns the node URL' do
            expect( node.url ).to eq '0.0.0.0:9999'
        end
    end

    describe '#alive?' do
        it 'returns true' do
            expect( node.alive? ).to be true
        end
    end

    describe '#peers' do
        it 'returns an array of peer URLs' do
            expect( node.peers ).to be_an Array
            expect( peer.peers ).to include '0.0.0.0:9999'
        end
    end

    describe '#grid_member?' do
        it 'returns true if node has peers' do
            expect( peer.grid_member? ).to be true
        end

        it 'returns false if node has no peers' do
            expect( node2.grid_member? ).to be false
        end
    end

    describe '#info' do
        it 'returns node information' do
            info = node.info
            expect( info ).to be_a Hash
            expect( info['url'] ).to eq '0.0.0.0:9999'
            expect( info['peers'] ).to be_an Array
            expect( info['unreachable_peers'] ).to be_an Array
        end
    end

    describe '#add_peer' do
        it 'adds a peer to the peer list' do
            test_node = Tiq::Node.new( url: '0.0.0.0:9997' ).start
            initial_count = node.peers.size
            node.add_peer( '0.0.0.0:9997' )
            sleep 0.1
            expect( node.peers.size ).to eq initial_count + 1
            expect( node.peers ).to include '0.0.0.0:9997'
            test_node.shutdown
            sleep 0.5
        end
    end

    describe '#remove_peer' do
        it 'removes a peer from the peer list' do
            test_node = Tiq::Node.new( url: '0.0.0.0:9996' ).start
            node.add_peer( '0.0.0.0:9996' )
            sleep 0.1
            node.remove_peer( '0.0.0.0:9996' )
            expect( node.peers ).not_to include '0.0.0.0:9996'
            test_node.shutdown
            sleep 0.5
        end
    end

    describe '#unplug' do
        it 'removes all peers' do
            peer.unplug
            sleep 0.5
            expect( peer.peers ).to be_empty
        end
    end

    describe '#channels' do
        it 'returns an empty array initially' do
            expect( node.channels ).to be_an Array
        end
    end

    describe '#create_channel' do
        it 'creates a new channel' do
            node.create_channel( 'test_channel' )
            sleep 0.1
            expect( node.channels ).to include 'test_channel'
            expect( node ).to respond_to :test_channel
        end

        it 'creates channel on peers when broadcast is true' do
            node.create_channel( 'broadcast_channel', true )
            sleep 0.5
            expect( node.channels ).to include 'broadcast_channel'
            expect( peer.channels ).to include 'broadcast_channel'
        end

        it 'does not create channel on peers when broadcast is false' do
            node.create_channel( 'local_channel', false )
            sleep 0.1
            expect( node.channels ).to include 'local_channel'
            expect( peer.channels ).not_to include 'local_channel'
        end
    end

    describe '#remove_channel' do
        it 'removes a channel' do
            node.create_channel( 'temp_channel' )
            sleep 0.1
            node.remove_channel( 'temp_channel' )
            expect( node.channels ).not_to include 'temp_channel'
        end
    end

    describe '#addons' do
        it 'returns an array of addon names' do
            expect( node.addons ).to be_an Array
        end
    end

    describe '#attach_addon' do
        it 'attaches an addon' do
            node.attach_addon( 'test_addon', proc { |arg| arg } )
            expect( node.addons ).to include 'test_addon'
        end

        it 'raises error if addon already exists' do
            node.attach_addon( 'duplicate', proc { |arg| arg } )
            expect {
                node.attach_addon( 'duplicate', proc { |arg| arg } )
            }.to raise_error( /already registered/ )
        end
    end

    describe '#call_addon' do
        it 'calls an attached addon' do
            node.attach_addon( 'echo', proc { |_, arg| arg } )
            result = node.call_addon( 'echo', 'hello' )
            expect( result ).to eq 'hello'
        end

        it 'raises error if addon not attached' do
            expect {
                node.call_addon( 'nonexistent', 'test' )
            }.to raise_error( /not attached/ )
        end
    end

    describe '#dettach_addon' do
        it 'removes an addon' do
            node.attach_addon( 'removable', proc { |arg| arg } )
            node.dettach_addon( 'removable' )
            expect( node.addons ).not_to include 'removable'
        end

        it 'raises error if addon not attached' do
            expect {
                node.dettach_addon( 'nonexistent' )
            }.to raise_error( /not attached/ )
        end
    end

    describe '.when_ready' do
        it 'calls block when node is ready' do
            test_node = Tiq::Node.new( url: '0.0.0.0:9995' ).start
            called = false
            Tiq::Node.when_ready( '0.0.0.0:9995' ) do
                called = true
            end
            sleep 1
            expect( called ).to be true
            test_node.shutdown
            sleep 0.5
        end
    end
end
