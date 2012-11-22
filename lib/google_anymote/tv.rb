require "google_anymote/version"
require 'socket'
require 'openssl'

##
# Module that understands the Google Anymote protocol.
module GoogleAnymote
  ##
  # Class to send events to a connected GoogleTV
  class TV
    attr_reader :host, :port, :cert, :cotext, :ssl_client, :remote, :request

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
    # Clean up any sockets and any other garbage.
    def finalize()
      @ssl_client.close
    end

    ##
    # Fling a URI to the Google TV connected to this object
    # This is used send the Google Chrome browser to a web page
    def fling_uri(uri)
      send_request RequestMessage.new(fling_message: Fling.new(uri: uri))
    end

    ##
    # Send a keystroke to the Google TV
    # This is used for things like hitting the ENTER key
    def send_keycode(keycode)
      send_request RequestMessage.new(key_event_message: KeyEvent.new(keycode: keycode, action: Action::DOWN))
      send_request RequestMessage.new(key_event_message: KeyEvent.new(keycode: keycode, action: Action::UP))
    end

    ##
    # Send a string to the Google TV.
    # This is used for things like typing into text boxes.
    def send_data(msg)
      send_request RequestMessage.new(data_message: Data1.new(type: "com.google.tv.string", data: msg))
    end

    ##
    # Move the mouse relative to its current position
    def move_mouse(x_delta, y_delta)
      send_request RequestMessage.new(mouse_event_message: MouseEvent.new(x_delta: x_delta, y_delta: y_delta))
    end

    ##
    # Scroll the mouse wheel a certain amount
    def scroll_mouse(x_amount, y_amount)
      send_request RequestMessage.new(mouse_wheel_message: MouseWheel.new(x_scroll: x_amount, y_scroll: y_amount))
    end


    private
    ##
    # Send a request to the Google TV and don't wait for a response
    def send_request(request)
      message = RemoteMessage.new(request_message: request).serialize_to_string
      message_size = [message.length].pack('N')
      @ssl_client.write(message_size + message)
    end

    ##
    # Send a message to the Google TV and return the response
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
