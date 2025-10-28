require 'spec_helper'

describe Tiq::Node::Channel do
    let( :node ) { @node ||= Tiq::Node.new( url: 'localhost:9999' ) }
    let( :peer ) { @peer ||= Tiq::Node.new( url: 'localhost:9998', peer: 'localhost:9999' ) }

    before( :each ) do
        node
        peer
        sleep 0.1
    end

    after( :each ) do
        @peer.shutdown
        @peer = nil
        @node.shutdown
        @node = nil
        sleep 1
    end

    it 'sets and gets data locally' do
        node.channel.set( 'key1', 'value1' )
        expect( node.channel.get( 'key1' ) ).to eq 'value1'
    end

    it 'propagates data to peers' do
        node.channel.set( 'key2', 'value2' )
        sleep 1
        expect( peer.channel.get( 'key2' ) ).to eq 'value2'
    end

    it 'does not propagate data when broadcast is false' do
        node.channel.set( 'key3', 'value3', false )
        sleep 0.1
        expect( peer.channel.get( 'key3' ) ).to be_nil
    end

    it 'calls on_set callbacks' do
        called = false
        peer.channel.on_set( 'key4' ) { |k, v| called = (k == 'key4' && v == 'value4') }
        node.channel.set( 'key4', 'value4' )
        sleep 1
        expect( called ).to be true
    end

    it 'calls on_delete callbacks' do
        called = false
        peer.channel.set( 'key5', 'value5' )
        sleep 1
        peer.channel.on_delete( 'key5' ) { |k| called = (k == 'key5') }
        node.channel.delete( 'key5' )
        sleep 1
        expect( called ).to be true
    end

    it 'does not call on_set callback when value is unchanged' do
        count = 0
        peer.channel.on_set( 'key6' ) { count += 1 }
        node.channel.set( 'key6', 'value6' )
        node.channel
    end
end
