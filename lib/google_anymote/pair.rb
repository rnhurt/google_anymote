require "google_anymote/version"
require 'socket'
require 'openssl'

##
# Module that understands the Google Anymote protocol.
module GoogleAnymote
  ##
  # Class to send events to a connected GoogleTV
  class Pair
    attr_reader :pair

    ##
    # Initializes the Pair class
    #
    # @param [String] client_name name of the client your connecting from
    # @param [String] service_name name of the service (generally 'AnyMote')
    # @return an instance of Pair
    def initialize(client_name = '', service_name = 'AnyMote')
      @pair = PairingRequest.new
      @pair.client_name  = 'grendel3'
      @pair.service_name = 'AnyMote'

      send_message(pair, OuterMessage::MessageType::MESSAGE_TYPE_PAIRING_REQUEST)
    end


    private

    ##
    # Format and send the message to the GoogleTV
    #
    # @param [String] msg message to send
    # @param [Object] type type of message to send
    # @return [Object] the OuterMessage response from the TV
    def send_message(msg, type)
      # Build the message and get it's size
      message = wrap_message(msg, type).serialize_to_string
      message_size = [message.length].pack('N')

      # Write the message to the SSL client and get the response
      @ssl_client.write(message_size + message)
      data = ""
      @ssl_client.readpartial(1000,data)
      @ssl_client.readpartial(1000,data)

      # Extract the response from the Google TV
      outer = OuterMessage.new
      outer.parse_from_string(data)

      puts "== SERVER SAID =="
      p "data: #{data}"
      p "  outer (status) : #{outer.status.to_s}"
      p "  outer (type)   : #{outer.type.to_s}"
      
      if !outer.payload.empty?
        p "  outer (payload): #{outer.payload.to_s}"
        payload = Options.new
        payload.parse_from_string(outer.payload.to_s)
        p "                 : #{payload.inspect}"
      end
      puts "================="

      return outer
    end

    ##
    # Wrap the message in an OuterMessage
    #
    # @param [String] msg message to send
    # @param [Object] type type of message to send
    # @return [Object] a properly formatted OuterMessage
    def wrap_message(msg, type)
      # Wrap it in an envelope
      outer = OuterMessage.new
      outer.protocol_version = 1
      outer.status  = OuterMessage::Status::STATUS_OK
      outer.type    = type
      outer.payload = msg.serialize_to_string

      return outer
    end

    ##
    # Encode the 
    # @param [String] secret pairing code from the TV's screen
    # @return [Digest] OpenSSL Digest containing the encoded secret
    def encode_hex_secret secret
        # # TODO(stevenle): Something further encodes the secret to a 64-char hex
        # # string. For now, use adb logcat to figure out what the expected challenge
        # # is. Eventually, make sure the encoding matches the server reference
        # # implementation:
        # #   http://code.google.com/p/google-tv-pairing-protocol/source/browse/src/com/google/polo/pairing/PoloChallengeResponse.java

        encoded_secret = [secret.to_i(16)].pack("N").unpack("cccc")[2..3].pack("c*")
        # nonce = encoded_secret[1]

        # Per "Polo Implementation Overview", section 6.1, client key material is
        # hashed first, followed by the server key material, followed by the nonce.
        digest = OpenSSL::Digest::Digest.new('sha256')
        digest << @ssl_client.cert.public_key.n.to_s(2)       # client modulus
        digest << @ssl_client.cert.public_key.e.to_s(2)       # client exponent
        digest << @ssl_client.peer_cert.public_key.n.to_s(2)  # server modulus
        digest << @ssl_client.peer_cert.public_key.e.to_s(2)  # server exponent

        digest << encoded_secret[encoded_secret.size / 2]
        return digest.digest
    end

    ##
    # Complete the pairing process
    #
    def pair
      puts "\nDEBUG: sending pairing request"


      # Build the options
      options       = Options.new
      encoding      = Options::Encoding.new
      encoding.type = Options::Encoding::EncodingType::ENCODING_TYPE_HEXADECIMAL
      encoding.symbol_length = 4
      options.input_encodings   << encoding
      options.output_encodings  << encoding
      puts "\nDEBUG: sending options request"
      send_message(options, OuterMessage::MessageType::MESSAGE_TYPE_OPTIONS)


      # Build configuration
      config = Configuration.new
      encoding      = Options::Encoding.new
      encoding.type = Options::Encoding::EncodingType::ENCODING_TYPE_HEXADECIMAL
      config.encoding               = encoding
      config.encoding.symbol_length = 4
      config.client_role            = Options::RoleType::ROLE_TYPE_INPUT
      puts "\nDEBUG: sending configuration request"
      send_message(config, OuterMessage::MessageType::MESSAGE_TYPE_CONFIGURATION)


      # Collect pairing code
      print 'Enter the code from the TV: '
      code = gets.chomp

      # Send secret
      secret = Secret.new
      secret.secret = encode_hex_secret(code)
      puts "\nDEBUG: sending secret request"
      send_message(secret, OuterMessage::MessageType::MESSAGE_TYPE_SECRET)

      # Clean up
      @ssl_client.close

      puts "\n\n- DONE -\n"
    end
  end
end
