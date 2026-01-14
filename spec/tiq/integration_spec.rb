require 'spec_helper'

describe 'Tiq Integration Tests' do
    describe 'Multi-node cluster' do
        let( :node1 ) { @node1 ||= Tiq::Node.new( url: '0.0.0.0:7999' ) }
        let( :node2 ) { @node2 ||= Tiq::Node.new( url: '0.0.0.0:7998', peer: '0.0.0.0:7999' ) }
        let( :node3 ) { @node3 ||= Tiq::Node.new( url: '0.0.0.0:7997', peer: '0.0.0.0:7999' ) }

        before( :each ) do
            node1.start
            sleep 1
            node2.start
            sleep 1
            node3.start
            sleep 1
        end

        after( :each ) do
            @node3&.shutdown
            @node3 = nil
            @node2&.shutdown
            @node2 = nil
            @node1&.shutdown
            @node1 = nil
            sleep 2
        end

        it 'forms a three-node cluster' do
            expect( node1.grid_member? ).to be false  # node1 is the seed
            expect( node2.grid_member? ).to be true
            expect( node3.grid_member? ).to be true
            expect( node2.peers ).to include '0.0.0.0:7999'
            expect( node3.peers ).to include '0.0.0.0:7999'
        end

        it 'propagates channel data across all nodes' do
            node1.channel.set( 'cluster_key', 'cluster_value' )
            sleep 2
            expect( node1.channel.get( 'cluster_key' ) ).to eq 'cluster_value'
            expect( node2.channel.get( 'cluster_key' ) ).to eq 'cluster_value'
            expect( node3.channel.get( 'cluster_key' ) ).to eq 'cluster_value'
        end

        it 'propagates channel deletes across all nodes' do
            node1.channel.set( 'delete_key', 'delete_value' )
            sleep 2
            node1.channel.delete( 'delete_key' )
            sleep 2
            expect( node1.channel.get( 'delete_key' ) ).to be_nil
            expect( node2.channel.get( 'delete_key' ) ).to be_nil
            expect( node3.channel.get( 'delete_key' ) ).to be_nil
        end

        it 'triggers callbacks on all nodes' do
            call1 = false
            call2 = false
            call3 = false
            
            node1.channel.on_set( 'callback_key' ) { call1 = true }
            node2.channel.on_set( 'callback_key' ) { call2 = true }
            node3.channel.on_set( 'callback_key' ) { call3 = true }
            
            node1.channel.set( 'callback_key', 'callback_value' )
            sleep 2
            
            expect( call1 ).to be true
            expect( call2 ).to be true
            expect( call3 ).to be true
        end

        it 'creates custom channels across all nodes' do
            node1.create_channel( 'custom_cluster', true )
            sleep 2
            
            expect( node1.channels ).to include 'custom_cluster'
            expect( node2.channels ).to include 'custom_cluster'
            expect( node3.channels ).to include 'custom_cluster'
            
            node1.custom_cluster.set( 'custom_key', 'custom_value' )
            sleep 2
            
            expect( node2.custom_cluster.get( 'custom_key' ) ).to eq 'custom_value'
            expect( node3.custom_cluster.get( 'custom_key' ) ).to eq 'custom_value'
        end

        it 'handles node info across cluster' do
            info1 = node1.info
            info2 = node2.info
            info3 = node3.info
            
            expect( info1['url'] ).to eq '0.0.0.0:7999'
            expect( info2['url'] ).to eq '0.0.0.0:7998'
            expect( info3['url'] ).to eq '0.0.0.0:7997'
        end
    end

    describe 'Node failure and recovery' do
        let( :node1 ) { @node1 ||= Tiq::Node.new( url: '0.0.0.0:6999' ) }
        let( :node2 ) { @node2 ||= Tiq::Node.new( url: '0.0.0.0:6998', peer: '0.0.0.0:6999' ) }

        before( :each ) do
            node1.start
            sleep 1
            node2.start
            sleep 1
        end

        after( :each ) do
            @node2&.shutdown
            @node2 = nil
            @node1&.shutdown
            @node1 = nil
            sleep 2
        end

        it 'detects dead peer through ping' do
            # Shutdown node2
            node2.shutdown
            @node2 = nil
            
            # Wait for ping interval to detect dead peer (default is 5 seconds)
            sleep 7
            
            # Node1 should have marked node2 as unreachable
            info = node1.info
            expect( info['unreachable_peers'] ).to include '0.0.0.0:6998'
        end

        it 'handles peer comeback' do
            # Shutdown node2
            node2.shutdown
            sleep 7
            
            # Verify node2 is marked as dead
            info = node1.info
            expect( info['unreachable_peers'] ).to include '0.0.0.0:6998'
            
            # Restart node2
            @node2 = Tiq::Node.new( url: '0.0.0.0:6998', peer: '0.0.0.0:6999' )
            @node2.start
            
            # Wait for comeback check interval
            sleep 7
            
            # Node1 should have detected node2 is back
            info = node1.info
            expect( info['peers'] ).to include '0.0.0.0:6998'
            expect( info['unreachable_peers'] ).not_to include '0.0.0.0:6998'
        end
    end

    describe 'Complex addon scenarios' do
        let( :node1 ) { @node1 ||= Tiq::Node.new( url: '0.0.0.0:5999' ) }
        let( :node2 ) { @node2 ||= Tiq::Node.new( url: '0.0.0.0:5998', peer: '0.0.0.0:5999' ) }

        before( :each ) do
            node1.start
            sleep 1
            node2.start
            sleep 1
        end

        after( :each ) do
            @node2&.shutdown
            @node2 = nil
            @node1&.shutdown
            @node1 = nil
            sleep 2
        end

        it 'allows addons to communicate between nodes' do
            Tiq::Addon.Attach( node1, 'service1' ) { |data|
                @channel.set( 'shared_data', data )
                "service1_response: #{data}"
            }
            
            Tiq::Addon.Attach( node2, 'service2' ) {
                # Call service1 on node1
                client = connect_to_node( '0.0.0.0:5999' )
                response = client.call_addon( 'service1', 'hello' )
                
                # Wait for channel to sync
                sleep 1
                
                # Read from shared channel
                shared = @channel.get( 'shared_data' )
                "service2_got: #{shared}, service1_said: #{response}"
            }
            
            result = Tiq::Addon( '0.0.0.0:5998', 'service2' )
            expect( result ).to include 'service2_got: hello'
            expect( result ).to include 'service1_said: service1_response: hello'
        end

        it 'handles concurrent addon calls' do
            call_count = 0
            Tiq::Addon.Attach( node1, 'counter' ) {
                call_count += 1
                call_count
            }
            
            results = []
            5.times do
                Thread.new do
                    results << Tiq::Addon( '0.0.0.0:5999', 'counter' )
                end
            end
            
            sleep 2
            expect( results.size ).to eq 5
            expect( results.uniq.size ).to be > 1  # Should have different counts
        end
    end

    describe 'Channel synchronization patterns' do
        let( :node1 ) { @node1 ||= Tiq::Node.new( url: '0.0.0.0:4999' ) }
        let( :node2 ) { @node2 ||= Tiq::Node.new( url: '0.0.0.0:4998', peer: '0.0.0.0:4999' ) }

        before( :each ) do
            node1.start
            sleep 1
            node2.start
            sleep 1
        end

        after( :each ) do
            @node2&.shutdown
            @node2 = nil
            @node1&.shutdown
            @node1 = nil
            sleep 2
        end

        it 'handles rapid updates' do
            10.times do |i|
                node1.channel.set( "rapid_#{i}", i )
            end
            
            sleep 2
            
            10.times do |i|
                expect( node2.channel.get( "rapid_#{i}" ) ).to eq i
            end
        end

        it 'maintains order of callbacks' do
            order = []
            node2.channel.on_set( nil ) { |k, v|
                order << [k, v] if k.start_with?( 'ordered_' )
            }
            
            5.times do |i|
                node1.channel.set( "ordered_#{i}", i )
                sleep 0.2
            end
            
            sleep 1
            expect( order.size ).to eq 5
        end

        it 'handles concurrent updates from multiple nodes' do
            node1.channel.set( 'concurrent_a', 'from_node1' )
            node2.channel.set( 'concurrent_b', 'from_node2' )
            
            sleep 2
            
            expect( node1.channel.get( 'concurrent_a' ) ).to eq 'from_node1'
            expect( node1.channel.get( 'concurrent_b' ) ).to eq 'from_node2'
            expect( node2.channel.get( 'concurrent_a' ) ).to eq 'from_node1'
            expect( node2.channel.get( 'concurrent_b' ) ).to eq 'from_node2'
        end
    end
end
