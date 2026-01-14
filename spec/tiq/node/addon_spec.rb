require 'spec_helper'

describe 'Tiq::Node::Addon' do
    let( :node ) { @node ||= Tiq::Node.new( url: '0.0.0.0:9999' ) }
    let( :peer ) { @peer ||= Tiq::Node.new( url: '0.0.0.0:9998', peer: '0.0.0.0:9999' ) }

    before( :each ) do
        node.start
        sleep 1
        peer.start
        sleep 0.1
    end

    after( :each ) do
        @peer.shutdown
        @peer = nil
        @node.shutdown
        @node = nil
        sleep 2
    end

    it 'attaches and calls an addon' do
        node.attach_addon 'echo', proc {  |_, arguments|
            arguments
        }
        result = node.call_addon( 'echo', 'hello' )
        expect( result ).to eq 'hello'
    end

    it 'lists addons' do
        node.attach_addon 'echo', proc {  |_, arguments|
            arguments
        }
        expect( node.addons ).to include 'echo'
    end

    describe 'addon with options' do
        it 'attaches addon with options' do
            node.attach_addon 'configured', proc { |_, arg| arg }, { timeout: 30 }
            result = node.call_addon( 'configured', 'test' )
            expect( result ).to eq 'test'
        end
    end

    describe 'addon with multiple arguments' do
        it 'handles multiple arguments' do
            node.attach_addon 'multi', proc { |_, a, b, c| [a, b, c] }
            result = node.call_addon( 'multi', 1, 2, 3 )
            expect( result ).to eq [1, 2, 3]
        end
    end

    # describe 'addon with block' do
    #     it 'handles addon with block parameter' do
    #         node.attach_addon 'with_block', proc { |_, arg, &block|
    #             block.call( arg.upcase ) if block
    #         }
    #         result = nil
    #         node.call_addon( 'with_block', 'test' ) { |_, r| result = r }
    #         sleep 0.1
    #         expect( result ).to eq 'TEST'
    #     end
    # end

    describe 'Tiq.Addon' do
        it 'calls an Addon to handle the request' do
            Tiq::Addon.Attach( node, 'echo' ) { |_, arguments|
                arguments
            }
            result = Tiq::Addon( '0.0.0.0:9999', 'echo', 'test' )
            expect( result ).to eq 'test'
        end

        it 'works with async block' do
            Tiq::Addon.Attach( node, 'async_echo' ) { |_, arguments|
                arguments
            }
            result = nil
            Tiq::Addon( '0.0.0.0:9999', 'async_echo', 'async_test' ) do |r|
                result = r
            end
            sleep 0.5
            expect( result ).to eq 'async_test'
        end
    end

    describe Tiq::Addon do
        describe '.Attach' do
            it 'attaches an Addon' do
                Tiq::Addon.Attach( node, 'echo' ) { |_, arguments|
                    arguments
                }
                result = Tiq::Addon( '0.0.0.0:9999', 'echo', 'test' )
                expect( result ).to eq 'test'
            end

            it 'attaches addon with access to node' do
                Tiq::Addon.Attach( node, 'node_info' ) {
                    node.url
                }
                result = Tiq::Addon( '0.0.0.0:9999', 'node_info' )
                expect( result ).to eq '0.0.0.0:9999'
            end

            it 'attaches addon with access to channel' do
                Tiq::Addon.Attach( node, 'channel_access' ) { |n|
                    n.channel.set( 'addon_key', 'addon_value' )
                    n.channel.get( 'addon_key' )
                }
                result = Tiq::Addon( '0.0.0.0:9999', 'channel_access' )
                expect( result ).to eq 'addon_value'
            end
        end

        describe '.Dettach' do
            it 'dettaches an Addon' do
                Tiq::Addon::Attach( node, 'echo' ) { |_, arguments|
                    arguments
                }
                result = Tiq::Addon( '0.0.0.0:9999', 'echo', 'test' )
                expect( result ).to eq 'test'

                Tiq::Addon.Dettach( node, 'echo' )

                result = nil
                begin
                    Tiq::Addon( '0.0.0.0:9999', 'echo', 'test' )
                rescue => e
                    result = e
                end

                expect(result.class).to be Toq::Exceptions::RemoteException
            end
        end

        describe 'Addon instance methods' do
            describe '#defer' do
                it 'defers blocking operations' do
                    Tiq::Addon.Attach( node, 'deferred' ) { |s|
                        result = nil
                        s.defer( proc { sleep 0.1; 'deferred_result' }, proc { |r| result = r } )
                        sleep 0.2
                        result
                    }
                    result = Tiq::Addon( '0.0.0.0:9999', 'deferred' )
                    expect( result ).to eq 'deferred_result'
                end
            end

            describe '#connect_to_node' do
                it 'connects to another node' do
                    Tiq::Addon.Attach( node, 'connector' ) { |s|
                        client = s.connect_to_node( '0.0.0.0:9998' )
                        client.alive?
                    }
                    result = Tiq::Addon( '0.0.0.0:9999', 'connector' )
                    expect( result ).to be true
                end
            end

            describe '#iterator_for' do
                it 'creates an iterator for a list' do
                    Tiq::Addon.Attach( node, 'iterator' ) { |s|
                        list = [1, 2, 3]
                        iter = s.iterator_for( list )
                        iter.class.to_s
                    }
                    result = Tiq::Addon( '0.0.0.0:9999', 'iterator' )
                    expect( result ).to include 'Iterator'
                end
            end
        end
    end
end
