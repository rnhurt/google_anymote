# Ruby Gem for the Google TV Pairing and Anymote Protocols

This gem implements the Google Anymote Protocol which is used to send events to Google TVs.
The protocol is based on a client-server model, with communications based on protocol buffers. 
Clients search for a server on the local network. When a client wants to connect to a server 
it has discovered, it does pairing authentication. After a successful pairing, both the client 
and the server have certificates specific to the client app, and can communicate in the future 
without the need to authenticate again. The transport layer uses TSL/SSL to protect messages 
against sniffing.

Note: I couldn't have made this without [Steven Le's Python client](https://github.com/stevenle/googletv-anymote).

## Installation

Add this line to your application's Gemfile:

    gem 'google_anymote'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install google_anymote

## Prerequisites

In order to send commands to a Google TV you must have an OpenSSL certificate.  This certificate
can be self-signed and is pretty easy to generate.  Just follow these steps 
(taken from http://www.akadia.com/services/ssh_test_certificate.html):

    $ openssl genrsa -des3 -out server.key 1024
    $ openssl req -new -key server.key -out server.csr
    $ openssl rsa -in server.key -out server.key
    $ openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
    $ cat server.key server.crt > cert.pem

Use the `cert.pem` as your certificate when you pair with the Google TV.

## Usage

### Command Line Utilities

This gem includes several command line utilities to get you up and running.

* <del>discover - searches your network for compatible Google TVs</del> - coming soon
* pair - helps you pair your computer to a particular Google TV

### As a gem

1. Create a GoogleAnymote::TV object
    
     gtv = GoogleAnymote::TV.new(my_cert, hostname)

2. Fling URIs to that TV 

    gtv.fling_uri('http://github.com')

## Contributing

1. Fork it
2. Create your feature branch ('git checkout -b my-new-feature')
3. Commit your changes ('git commit -am 'Added some feature')
4. Push to the branch ('git push origin my-new-feature')
5. Create new Pull Request
