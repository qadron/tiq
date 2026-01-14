require 'spec_helper'

describe Tiq::Client do
    let( :node ) { @node ||= Tiq::Node.new( url: '0.0.0.0:8999' ) }
    let( :client ) { @client ||= Tiq::Client.new( '0.0.0.0:8999' ) }

    before( :each ) do
        node.start
        sleep 0.5
    end

    after( :each ) do
        @client&.close
        @client = nil
        @node&.shutdown
        @node = nil
        sleep 1
    end

    describe '#initialize' do
        it 'initializes with URL' do
            expect( client ).to be_a Tiq::Client
        end

        it 'accepts handler option' do
            custom_client = Tiq::Client.new( '0.0.0.0:8999', handler: 'custom' )
            expect( custom_client ).to be_a Tiq::Client
            custom_client.close
        end

        it 'accepts serializer option' do
            yaml_client = Tiq::Client.new( '0.0.0.0:8999', serializer: YAML )
            expect( yaml_client ).to be_a Tiq::Client
            yaml_client.close
        end
    end

    describe 'RPC calls' do
        it 'calls alive? method on node' do
            result = client.alive?
            expect( result ).to be true
        end

        it 'calls peers method on node' do
            result = client.peers
            expect( result ).to be_an Array
        end

        it 'calls info method on node' do
            result = client.info
            expect( result ).to be_a Hash
            expect( result['url'] ).to eq '0.0.0.0:8999'
        end

        it 'calls methods with blocks asynchronously' do
            called = false
            result = nil
            client.alive? do |r|
                result = r
                called = true
            end
            sleep 0.5
            expect( called ).to be true
            expect( result ).to be true
        end
    end

    describe 'addon calls' do
        before( :each ) do
            node.attach_addon( 'test', proc { |_, arg| "echo: #{arg}" } )
        end

        it 'calls addon through client' do
            result = client.call_addon( 'test', 'hello' )
            expect( result ).to eq 'echo: hello'
        end

        it 'calls addon asynchronously' do
            result = nil
            client.call_addon( 'test', 'async' ) do |r|
                result = r
            end
            sleep 0.5
            expect( result ).to eq 'echo: async'
        end
    end

    describe 'channel operations' do
        it 'sets and gets channel data through client' do
            channel_client = Tiq::Client.new( '0.0.0.0:8999', handler: 'channel' )
            channel_client.set( 'test_key', 'test_value' )
            sleep 0.1
            result = channel_client.get( 'test_key' )
            expect( result ).to eq 'test_value'
            channel_client.close
        end
    end

    describe 'error handling' do
        it 'handles connection to non-existent node' do
            bad_client = Tiq::Client.new( '0.0.0.0:7777', client_max_retries: 1 )
            expect { bad_client.alive? }.to raise_error Toq::Exceptions::ConnectionError
        end
    end
end
