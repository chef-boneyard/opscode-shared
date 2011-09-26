require 'opscode/json_session'
require 'action_controller/flash'
require 'action_controller/session/cookie_store'

module Opscode
  class JSONFlashHash < ActionController::Flash::FlashHash
    include JSONFlashHashImpl
  end
end

# Register the new session backend
module ActionController
  module Session
    # Bad camel-casing is required by Ruby
    class JsonCookieStore < CookieStore
      def verifier_for(secret, digest)
        key = secret.respond_to?(:call) ? secret.call : secret
        Opscode::JSONMessageVerifier.new(key, digest)
      end
    end
  end
end
