require "google_anymote/version"
require 'socket'
require 'openssl'

##
# Module that understands the Google Anymote protocol.
module GoogleAnymote
  ##
  # Class to send events to a connected GoogleTV
  class TV
    attr_reader :host, :port, :cert, :cotext, :ssl_client, :remote, :request, :fling

    ##
    # Initializes the TV class.
    #
    # @param [Object] cert SSL certificate for this client
    # @param [String] host hostname or IP address of the Google TV
    # @param [Number] port port number of the Google TV
    # @return an instance of TV
    def initialize(cert, host, port = 9551)
      @host = host
      @port = port
      @cert = cert
      @remote  = RemoteMessage.new
      @request = RequestMessage.new
      @fling   = Fling.new

      # Build the SSL stuff
      @context       = OpenSSL::SSL::SSLContext.new
      @context.key   = OpenSSL::PKey::RSA.new @cert
      @context.cert  = OpenSSL::X509::Certificate.new @cert

      connect_to_unit
    end

    ##
    # Connect this object to a Google TV
    def connect_to_unit
      puts "Connecting to '#{@host}..."
      begin
        tcp_client  = TCPSocket.new @host, @port
        @ssl_client = OpenSSL::SSL::SSLSocket.new tcp_client, @context
        @ssl_client.connect
      rescue Exception => e
        puts "Could not connect to '#{@host}: #{e}"
      end
    end

    ##
    # Clean up any sockets or other garbage.
    def finalize()
      @ssl_client.close
    end

    ##
    # Fling a URI to the Google TV connected to this object
    def fling_uri(uri)
      @fling.uri = uri
      @request.fling_message = fling
      @remote.request_message = @request
      send_message(@remote)
    end

    private
    ##
    # Send a message to the Google TV
    # @param [String] msg message to send to the TV
    # @return [String] raw data sent back from the TV
    def send_message(msg)
      # Build the message and get it's size
      message = msg.serialize_to_string
      message_size = [message.length].pack('N')

      # Try to send the message
      try_again = true
      begin
        data = ""
        @ssl_client.write(message_size + message)
        @ssl_client.readpartial(1000,data)
      rescue
        # Sometimes our connection might drop or something, so
        # we'll reconnect to the unit and try to send the message again.
        if try_again
          try_again = false
          connect_to_unit
          retry
        else
          # Looks like we couldn't connect to the unit after all.
          puts "message not sent"
        end
      end

      return data
    end
  end
end
