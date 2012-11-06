module GoogleAnymote
  # A general purpose error
  class Error < StandardError; end

  # Raised when a pairing operation fails for some reason
  class PairingFailed < Error; end
end