require 'spec_helper'

describe Tiq do
    describe 'VERSION' do
        it 'has a version number' do
            expect( Tiq::VERSION ).not_to be_nil
        end

        it 'has a valid semantic version format' do
            expect( Tiq::VERSION ).to match( /^\d+\.\d+\.\d+$/ )
        end
    end

    describe 'module structure' do
        it 'defines the Tiq module' do
            expect( defined?( Tiq ) ).to eq 'constant'
        end

        it 'defines the Node class' do
            expect( defined?( Tiq::Node ) ).to eq 'constant'
        end

        it 'defines the Client class' do
            expect( defined?( Tiq::Client ) ).to eq 'constant'
        end

        it 'defines the Channel class' do
            expect( defined?( Tiq::Node::Channel ) ).to eq 'constant'
        end

        it 'defines the Addon module' do
            expect( defined?( Tiq::Addon ) ).to eq 'constant'
        end

        it 'defines the Node::Addon class' do
            expect( defined?( Tiq::Node::Addon ) ).to eq 'constant'
        end
    end

    describe 'Addon module methods' do
        let( :node ) { @node ||= Tiq::Node.new( url: 'localhost:3999' ) }

        before( :each ) do
            node.start
            sleep 1
        end

        after( :each ) do
            @node&.shutdown
            @node = nil
            sleep 1
        end

        it 'provides Tiq.Addon method' do
            expect( Tiq ).to respond_to( :Addon )
        end

        it 'provides Tiq::Addon.Attach method' do
            expect( Tiq::Addon ).to respond_to( :Attach )
        end

        it 'provides Tiq::Addon.Dettach method' do
            expect( Tiq::Addon ).to respond_to( :Dettach )
        end

        it 'calls addon via Tiq.Addon' do
            Tiq::Addon.Attach( node, 'test' ) { |arg| arg }
            result = Tiq.Addon( 'localhost:3999', 'test', 'value' )
            expect( result ).to eq 'value'
        end

        it 'calls addon via Tiq.Addon with client object' do
            Tiq::Addon.Attach( node, 'test2' ) { |arg| arg }
            client = Tiq::Client.new( 'localhost:3999' )
            result = Tiq.Addon( client, 'test2', 'value2' )
            expect( result ).to eq 'value2'
            client.close
        end
    end
end
