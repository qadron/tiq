require 'spec_helper'

describe Tiq::Node::Channel do
    let( :node ) { @node ||= Tiq::Node.new( url: '0.0.0.0:9999' ) }
    let( :peer ) { @peer ||= Tiq::Node.new( url: '0.0.0.0:9998', peer: '0.0.0.0:9999' ) }

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
        sleep 1
        node.channel.set( 'key6', 'value6' )
        sleep 1
        expect( count ).to eq 1
    end

    describe '#to_h' do
        it 'returns a hash of channel data' do
            node.channel.set( 'key7', 'value7' )
            hash = node.channel.to_h
            expect( hash ).to be_a Hash
            expect( hash['key7'] ).to eq 'value7'
        end
    end

    describe '#update' do
        it 'updates channel data from hash' do
            node.channel.update( { 'key8' => 'value8', 'key9' => 'value9' } )
            expect( node.channel.get( 'key8' ) ).to eq 'value8'
            expect( node.channel.get( 'key9' ) ).to eq 'value9'
        end
    end

    describe 'catch-all callbacks' do
        it 'calls catch-all on_set callback for any key' do
            calls = []
            node.channel.on_set( nil ) { |k, v| calls << [k, v] }
            node.channel.set( 'key10', 'value10' )
            sleep 0.1
            node.channel.set( 'key11', 'value11' )
            sleep 0.1
            expect( calls ).to include( ['key10', 'value10'] )
            expect( calls ).to include( ['key11', 'value11'] )
        end
    end

    describe 'multiple callbacks' do
        it 'calls all registered callbacks for a key' do
            call1 = false
            call2 = false
            node.channel.on_set( 'key12' ) { call1 = true }
            node.channel.on_set( 'key12' ) { call2 = true }
            node.channel.set( 'key12', 'value12' )
            sleep 0.1
            expect( call1 ).to be true
            expect( call2 ).to be true
        end
    end

    describe 'broadcast behavior' do
        it 'broadcasts delete to peers' do
            node.channel.set( 'key13', 'value13' )
            sleep 1
            expect( peer.channel.get( 'key13' ) ).to eq 'value13'
            node.channel.delete( 'key13' )
            sleep 1
            expect( peer.channel.get( 'key13' ) ).to be_nil
        end

        it 'does not broadcast delete when broadcast is false' do
            node.channel.set( 'key14', 'value14' )
            sleep 1
            node.channel.delete( 'key14', false )
            sleep 0.1
            expect( node.channel.get( 'key14' ) ).to be_nil
            # Note: peer still has the value since we didn't broadcast the delete
        end
    end
end
