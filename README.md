# Tiq

<table>
    <tr>
        <th>Github page</th>
        <td><a href="http://github.com/qadron/tiq">http://github.com/qadron/tiq</a></td>
     </tr>
    <tr>
        <th>Code Documentation</th>
        <td><a href="http://rubydoc.info/github/qadron/tiq/">http://rubydoc.info/github/qadron/tiq/</a></td>
    </tr>
    <tr>
       <th>Author</th>
       <td><a href="mailto:tasos.laskos@gmail.com">Tasos Laskos</a></td>
    </tr>
    <tr>
        <th>Copyright</th>
        <td><a href="mailto:tasos.laskos@gmail.com">Tasos Laskos</a></td>
    </tr>
    <tr>
        <th>License</th>
        <td><a href="file.LICENSE.html">MPL v2</a></td>
    </tr>
</table>

## Synopsis

Tiq is a simple and lightweight clustering solution.

This implementation is based on [Toq](https://github.com/qadron/toq) to cover Remote Procedure Call needs.

## Concepts

There are a few key concepts in `Tiq`:

### Node

`Tiq::Node` offers _Node_ representations, _server-side_ presences if you must.

To start a _Node_, you need to create a class that inherits from `Tiq::Node`
and instantiate it with a URL to bind to.

```ruby
cass MyNode < Tiq::Node
end

node = MyNode.new( url: "localhost:9999" )
```

### Cluster

To create a _Cluster_, you need to create another _Node_ and specify any already
existing one, as a _Cluster_ member, to be its _peer_.

Any existing _Node_ would do.

```ruby
class MySecondNode < Tiq::Node
end

node_2 = MySecondNode.new( url: "localhost:9998", peer: 'localhost:9999' )
```

### Client

`Tiq::Client` offers a _Client_ to enable _Node_/User communications.

```ruby
client = MyClient.new( "localhost:9999" )

# Issue calls on the server side and get us the responses.
# Client will return `true`.
p client.alive?
# Client will return information about the Grid members.
p client.peers
# Client will return information about the Grid members.
p client.info
```

### Channel

Chanel _Nodes_ offer client-side access to the _Shared Data_; a Shared HashMap.

This enables the establishment of channels via callbacks upon _Data_
operations.

```ruby
class MyNode < Tiq::Node
end

class MySecondNode < Tiq::Node
end

class MyChannelNode < Tiq::Node
end

# Set up initial Node, the start of the cluster.
node_1  = MyNode.new( url: "localhost:9999" )
node_2  = MySecondNode.new( url: "localhost:9998", peer: 'localhost:9999' )
channel = MyChannelNode.new( url: "localhost:9997", peer: 'localhost:9999' ).channel
sleep 1

channel.on_set :my_signal do |value|
    p "#{:on_set} - #{value}"
end

node_1.data.set :my_signal, 'tada!'
sleep 1
```

### Add-ons

_Node_ Add-ons are most commonly _Services_, and are are immensly easy to deploy
and have up and running for
every _Node_.

```ruby
class MyNode < Tiq::Node
end

# Set up initial Node.
node_1 = MyNode.new( url: "localhost:9999" )

# Add a service to the node, called :poll.
Tiq::Addon::Attach node_1, :poll do |arguments = nil|
    p "SERVICE: #{arguments}"
end

# Interact with the service via a Client.
Tiq::Addon "localhost:9999", :poll, 'ping' do
    puts "CLIENT: #{r}"
end
```

### Channel Shared Data

Data can be shared across _Nodes_ by means of broadcasting upon
change - optional.

```ruby
class MyNode < Tiq::Node
end

class MySecondNode < Tiq::Node
end

# Set up initial Node, the start of the cluster.
node_1 = MyNode.new( url: "localhost:9999" )
node_2 = MySecondNode.new( url: "localhost:9998", peer: 'localhost:9999' )

sleep 1

node_2.channel.on_set :my_signal do |value|
    p "#{:on_set} - #{value}"
end

node_1.channel.set :my_signal, 'tada!'
sleep 1
```

#### Custom groups

```ruby
require 'tiq'

n1 = Tiq::Node.new( url: "localhost:9999" ).start
n2 = Tiq::Node.new( url: "localhost:9998", peer: 'localhost:9999' ).start

# Add as many groups/channels/shared-data structures as you want.
n1.create_channel 'agents'

n1.agents.set :a1, 99
sleep 1

p n2.agents.get :a1
```

## Installation

    gem install tiq

## License

Tiq is provided under the 3-clause BSD license.
See the `LICENSE` file for more information.
