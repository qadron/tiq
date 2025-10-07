# Tiq

<table>
    <tr>
        <th>Version</th>
        <td>0.0.4</td>
    </tr>
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
        <td>2022 <a href="https://ecsypno.com">Ecsypno</a></td>
    </tr>
    <tr>
        <th>License</th>
        <td><a href="file.LICENSE.html">3-clause BSD</a></td>
    </tr>
</table>

## Synopsis

Tiq is a simple and lightweight Remote Procedure Call protocol and implementation.

This implementation is based on [Raktr](https://github.com/qadron/raktr).

## Features

 - Extremely lightweight.
 - Very simple design.
 - TLS encryption.
 - Configurable serializer.
    - Can intercept RPC responses and translate them into native objects for
        when using serializers that only support basic types, like JSON or MessagePack.
 - Token-based authentication.
 - Pure-Ruby.
 - Multi-platform, tested on:
    - Linux
    - OSX
    - Windows

## Installation

    gem install tiq

## Running the Specs

    bundle install
    rake spec

## Protocol specifications

You can find the RPC protocol specification at the
[Wiki](https://github.com/Arachni/arachni-rpc/wiki).

## License

Tiq is provided under the 3-clause BSD license.
See the `LICENSE` file for more information.
