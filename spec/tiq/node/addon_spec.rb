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
        node.attach_addon 'echo', proc {  |arguments|
            arguments
        }
        result = node.call_addon( 'echo', 'hello' )
        expect( result ).to eq 'hello'
    end

    it 'lists addons' do
        node.attach_addon 'echo', proc {  |arguments|
            arguments
        }
        expect( node.addons ).to include 'echo'
    end

    describe 'Tiq.Addon' do
        it 'calls an Addon to handle the request' do
            Tiq::Addon.Attach( node, 'echo' ) { |arguments|
                arguments
            }
            result = Tiq::Addon( 'localhost:9999', 'echo', 'test' )
            expect( result ).to eq 'test'
        end
    end

    describe Tiq::Addon do
        describe '.Attach' do
            it 'attaches an Addon' do
                Tiq::Addon.Attach( node, 'echo' ) { |arguments|
                    arguments
                }
                result = Tiq::Addon( 'localhost:9999', 'echo', 'test' )
                expect( result ).to eq 'test'
            end
        end

        describe '.Dettach' do
            it 'dettaches an Addon' do
                Tiq::Addon::Attach( node, 'echo' ) { |arguments|
                    arguments
                }
                result = Tiq::Addon( 'localhost:9999', 'echo', 'test' )
                expect( result ).to eq 'test'

                Tiq::Addon.Dettach( node, 'echo' )

                result = nil
                begin
                    Tiq::Addon( 'localhost:9999', 'echo', 'test' )
                rescue => e
                    result = e
                end

                expect(result.class).to be Toq::Exceptions::RemoteException
            end
        end
    end
end
