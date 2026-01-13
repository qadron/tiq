# Tiq Test Suite

This directory contains a comprehensive test suite for the Tiq clustering library.

## Test Files

### Unit Tests

1. **spec/tiq_spec.rb** - Tests for the main Tiq module
   - Version number and format validation
   - Module structure verification
   - Addon module methods (Tiq.Addon, Tiq::Addon.Attach, Tiq::Addon.Dettach)

2. **spec/tiq/client_spec.rb** - Tests for Tiq::Client
   - Client initialization with various options (URL, handler, serializer)
   - RPC method calls (alive?, peers, info)
   - Synchronous and asynchronous calls
   - Addon calls through client
   - Channel operations through client
   - Error handling for connection failures

3. **spec/tiq/node_spec.rb** - Tests for Tiq::Node
   - Node properties (#url, #alive?, #peers, #grid_member?, #info)
   - Peer management (#add_peer, #remove_peer, #unplug)
   - Channel management (#channels, #create_channel, #remove_channel)
   - Addon management (#addons, #attach_addon, #call_addon, #dettach_addon)
   - Class methods (.when_ready)
   - Broadcasting behavior for channel creation

4. **spec/tiq/node/channel_spec.rb** - Tests for Tiq::Node::Channel
   - Basic operations (set, get, delete)
   - Data propagation across peers
   - Broadcast control (with broadcast=true/false)
   - Callbacks (on_set, on_delete)
   - Catch-all callbacks (on_set with nil key)
   - Multiple callbacks on same key
   - Data export and import (to_h, update)
   - Delete broadcasting

5. **spec/tiq/node/addon_spec.rb** - Tests for Tiq::Node::Addon
   - Basic addon attachment and calling
   - Addon listing
   - Addon with options
   - Multiple arguments handling
   - Block parameter handling
   - Tiq.Addon helper function
   - Tiq::Addon.Attach and Dettach
   - Addon instance methods:
     - #defer (for blocking operations)
     - #connect_to_node (for inter-node communication)
     - #iterator_for (for concurrent operations)
   - Addon access to node and channel

### Integration Tests

6. **spec/tiq/integration_spec.rb** - Comprehensive integration tests
   - **Multi-node cluster scenarios:**
     - Three-node cluster formation
     - Channel data propagation across all nodes
     - Channel delete propagation
     - Callback triggering on all nodes
     - Custom channel creation across cluster
     - Node info across cluster
   
   - **Node failure and recovery:**
     - Dead peer detection through ping mechanism
     - Peer comeback detection and re-integration
   
   - **Complex addon scenarios:**
     - Inter-node addon communication
     - Concurrent addon calls
   
   - **Channel synchronization patterns:**
     - Rapid updates handling
     - Callback order maintenance
     - Concurrent updates from multiple nodes

## Running Tests

### Run all tests:
```bash
bundle exec rspec
```

### Run specific test files:
```bash
bundle exec rspec spec/tiq_spec.rb
bundle exec rspec spec/tiq/client_spec.rb
bundle exec rspec spec/tiq/node_spec.rb
bundle exec rspec spec/tiq/node/channel_spec.rb
bundle exec rspec spec/tiq/node/addon_spec.rb
bundle exec rspec spec/tiq/integration_spec.rb
```

### Run with specific format:
```bash
bundle exec rspec --format documentation
bundle exec rspec --format progress
```

## Test Coverage

The test suite provides comprehensive coverage of:
- ✅ Core node functionality and lifecycle
- ✅ Client-server communication
- ✅ Channel-based data sharing and synchronization
- ✅ Callback mechanisms
- ✅ Addon/service system
- ✅ Multi-node clustering
- ✅ Peer management and failure detection
- ✅ Peer recovery
- ✅ Error handling
- ✅ Concurrent operations

## Notes

- Tests use different port ranges to avoid conflicts:
  - tiq_spec.rb: 3999
  - client_spec.rb: 8999
  - node_spec.rb and channel_spec.rb: 9999, 9998, 9997, 9996, 9995
  - integration_spec.rb: 7999-7997 (cluster), 6999-6998 (failure), 5999-5998 (addon), 4999-4998 (sync)
  
- Tests include appropriate sleep intervals to allow for:
  - Node startup and initialization
  - Network communication
  - Peer discovery and synchronization
  - Callback execution

- Integration tests are more comprehensive but take longer to run due to the nature of distributed system testing.
