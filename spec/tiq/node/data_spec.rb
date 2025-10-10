require 'spec_helper'

describe Tiq::Node::Data do
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
        node.data.set( 'key1', 'value1' )
        expect( node.data.get( 'key1' ) ).to eq 'value1'
    end

    it 'propagates data to peers' do
        node.data.set( 'key2', 'value2' )
        sleep 1
        expect( peer.data.get( 'key2' ) ).to eq 'value2'
    end

    it 'does not propagate data when broadcast is false' do
        node.data.set( 'key3', 'value3', false )
        sleep 0.1
        expect( peer.data.get( 'key3' ) ).to be_nil
    end

    it 'calls on_set callbacks' do
        called = false
        peer.data.on_set( 'key4' ) { |k, v| called = (k == 'key4' && v == 'value4') }
        node.data.set( 'key4', 'value4' )
        sleep 1
        expect( called ).to be true
    end

    it 'calls on_delete callbacks' do
        called = false
        peer.data.set( 'key5', 'value5' )
        sleep 1
        peer.data.on_delete( 'key5' ) { |k| called = (k == 'key5') }
        node.data.delete( 'key5' )
        sleep 1
        expect( called ).to be true
    end

    it 'does not call on_set callback when value is unchanged' do
        count = 0
        peer.data.on_set( 'key6' ) { count += 1 }
        node.data.set( 'key6', 'value6' )
        node.data
    end
end
