require "google_anymote/version"
require 'socket'
require 'openssl'

##
# Module that understands the Google Anymote protocol.
module GoogleAnymote
  ##
  # Class to send events to a connected GoogleTV
  class Pair
    attr_reader :pair, :cert, :host, :gtv

    ##
    # Initializes the Pair class
    #
    # @param [Object] cert SSL certificate for this client
    # @param [String] host hostname or IP address of the Google TV
    # @param [String] client_name name of the client your connecting from
    # @param [String] service_name name of the service (generally 'AnyMote')
    # @return an instance of Pair
    def initialize(cert, host, client_name = '', service_name = 'AnyMote')
      @pair = PairingRequest.new
      @cert = cert
      @host = host
      @pair.client_name  = client_name
      @pair.service_name = service_name
    end


    ##
    # Start the pairing process
    #
    # Once the TV recieves the pairing request it will display a 4 digit number.
    # This number needs to be feed into the next step in the process, complete_pairing().
    #
    def start_pairing
      @gtv = GoogleAnymote::TV.new(@cert, host, 9551 + 1)

      # Let the TV know that we want to pair with it
      send_message(pair, OuterMessage::MessageType::MESSAGE_TYPE_PAIRING_REQUEST)

      # Build the options and send them to the TV
      options       = Options.new
      encoding      = Options::Encoding.new
      encoding.type = Options::Encoding::EncodingType::ENCODING_TYPE_HEXADECIMAL
      encoding.symbol_length = 4
      options.input_encodings   << encoding
      options.output_encodings  << encoding
      send_message(options, OuterMessage::MessageType::MESSAGE_TYPE_OPTIONS)

      # Build configuration and send it to the TV
      config        = Configuration.new
      encoding      = Options::Encoding.new
      encoding.type = Options::Encoding::EncodingType::ENCODING_TYPE_HEXADECIMAL
      config.encoding               = encoding
      config.encoding.symbol_length = 4
      config.client_role            = Options::RoleType::ROLE_TYPE_INPUT
      outer = send_message(config, OuterMessage::MessageType::MESSAGE_TYPE_CONFIGURATION)
      
      raise PairingFailed, outer.status unless OuterMessage::Status::STATUS_OK == outer.status
    end

    ##
    # Complete the pairing process
    # @param [String] code The code displayed on the Google TV we are trying to pair with.
    #
    def complete_pairing(code)
      # Send secret code to the TV to compete the pairing process
      secret = Secret.new
      secret.secret = encode_hex_secret(code)
      outer = send_message(secret, OuterMessage::MessageType::MESSAGE_TYPE_SECRET)

      # Clean up
      @gtv.ssl_client.close

      raise PairingFailed, outer.status unless OuterMessage::Status::STATUS_OK == outer.status
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
      @gtv.ssl_client.write(message_size + message)
      data = ""
      @gtv.ssl_client.readpartial(1000,data)
      @gtv.ssl_client.readpartial(1000,data)

      # Extract the response from the Google TV
      outer = OuterMessage.new
      outer.parse_from_string(data)

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
    # Encode the secret from the TV into an OpenSSL Digest
    #
    # @param [String] secret pairing code from the TV's screen
    # @return [Digest] OpenSSL Digest containing the encoded secret
    def encode_hex_secret secret
      # TODO(stevenle): Something further encodes the secret to a 64-char hex
      # string. For now, use adb logcat to figure out what the expected challenge
      # is. Eventually, make sure the encoding matches the server reference
      # implementation:
      #   http://code.google.com/p/google-tv-pairing-protocol/source/browse/src/com/google/polo/pairing/PoloChallengeResponse.java

      encoded_secret = [secret.to_i(16)].pack("N").unpack("cccc")[2..3].pack("c*")

      # Per "Polo Implementation Overview", section 6.1, client key material is
      # hashed first, followed by the server key material, followed by the nonce.
      digest = OpenSSL::Digest::Digest.new('sha256')
      digest << @gtv.ssl_client.cert.public_key.n.to_s(2)       # client modulus
      digest << @gtv.ssl_client.cert.public_key.e.to_s(2)       # client exponent
      digest << @gtv.ssl_client.peer_cert.public_key.n.to_s(2)  # server modulus
      digest << @gtv.ssl_client.peer_cert.public_key.e.to_s(2)  # server exponent

      digest << encoded_secret[encoded_secret.size / 2]
      return digest.digest
    end
  end
end
