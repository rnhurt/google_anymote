# GoogleAnymote

This gem implements the Google Anymote Protocol which is used to send events to Google TVs.
The protocol is based on a client-server model, with communications based on protocol buffers. 
Clients search for a server on the local network. When a client wants to connect to a server 
it has discovered, it does pairing authentication. After a successful pairing, both the client 
and the server have certificates specific to the client app, and can communicate in the future 
without the need to authenicate again. The transport layer uses TSL/SSL to protect messages 
against sniffing.

## Installation

Add this line to your application's Gemfile:

    gem 'google_anymote'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install google_anymote

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
