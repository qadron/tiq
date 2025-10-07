require 'yaml'
require_relative '../lib/tiq/node/service'
require_relative '../lib/tiq/node'

class MyNode < Tiq::Node
end

class MySecondNode < Tiq::Node
end

class MyService < Tiq::Node::Service
end

class MyChannel < Tiq::Channel
end

class MyClient < Tiq::Client
end

# Set up initial Node, the start of the cluster.
node_1    = MyNode.new( url: "localhost:9999" )
# Provide the Node's functionality as a service
# and also get some goodies to help towards that goal.
service_1 = MyService.new( node_1 )
# Instead of a Client, get a Channel for synchronization
# and communication everywhere in the Grid.
channel   = MyChannel.new( "localhost:9999" )

# Subsequent nodes should point at any existing ones, as a peer,
# in order to join the Grid.
node_2    = MySecondNode.new( url: "localhost:9998", peer: 'localhost:9999' )
service_2 = MyService.new( node_2 )
# Dryer and more targeted towards a polling approach, rather than an evented one.
client    = MyClient.new( "localhost:9998" )

# Set the Shared Grid data to value `34` with the key `:n2`.
service_1.data.set :n2, 34
# Get the Shared Grid data of key `:n2`.
p service_1.data.get :n2

sleep 1

# Set the Shared Grid data of key `:n1` to `12`.
service_2.data.set :n1, 12

p '-----'

# Channel brought into action where the key `n3` is set a value.
channel.on_set :n3 do |val|
    p :on_set
    puts val
end

# Set key `n3` to `:blah` via the Service.
service_2.data.set :n3, :blah

# Client will return `true`.
p client.alive?
# Client will return information about the Grid members.
p client.peers
# Client will return information about the Grid members.
p client.info

# sleep
