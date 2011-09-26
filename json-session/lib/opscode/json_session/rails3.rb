require 'opscode/json_session'
require 'action_dispatch/middleware/flash'
require 'action_dispatch/middleware/cookies'

module Opscode
  class JSONFlashHash < ActionDispatch::Flash::FlashHash
    include JSONFlashHashImpl
  end
end

module ActionDispatch
  class Cookies
    class SignedCookieJar
      initialize = instance_method(:initialize)
      define_method(:initialize) do |parent_jar, secret|
        initialize.bind(self).call(parent_jar, secret)
        @verifier = Opscode::JSONMessageVerifier.new(secret)
      end
    end
  end
end
