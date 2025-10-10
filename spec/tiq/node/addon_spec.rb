require 'spec_helper'

describe 'Tiq::Node::Addon' do
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

    it 'attaches and calls an addon' do
        node.attach_addon( 'echo', 'Tiq::Service::Echo' )
        result = node.call_addon( 'echo', 'hello' )
        expect( result ).to eq 'hello'
    end

    it 'lists addons' do
        node.attach_addon( 'echo', 'Tiq::Service::Echo' )
        expect( node.addons ).to include 'echo'
    end
end
