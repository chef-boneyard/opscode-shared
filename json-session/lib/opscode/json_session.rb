require 'yajl'

module Opscode
  begin
    # Rails 3
    require 'action_dispatch/middleware/flash'
    flash_hash = ActionDispatch::Flash::FlashHash
  rescue MissingSourceFile
    # Rails 2
    require 'action_controller/flash'
    flash_hash = ActionController::Flash::FlashHash
  end

  class JSONFlashHash < flash_hash
    def initialize(data)
      super()
      # Force symbolic keys since that is the convention Rails uses
      replace(data.inject({}){|memo, (k, v)| memo[k.to_sym] = v; memo})
    end

    # Work around HashWithIndifferentAccess trying to convert this back (Rails 2 only)
    def with_indifferent_access
      self
    end
  end
end

# New message verifier that uses JSON for storage
module ActiveSupport
  class JSONMessageVerifier < MessageVerifier
    def verify(signed_message)
      raise InvalidSignature if signed_message.blank?
 
      data, digest = signed_message.split("--")
      if data.present? && digest.present? && secure_compare(digest, generate_digest(data))
        str = ActiveSupport::Base64.decode64(data)
        if str[0..0] == '{'
          parser = Yajl::Parser.new
          data = parser.parse(str).with_indifferent_access
          data['flash'] = Opscode::JSONFlashHash.new(data['flash']) if data['flash']
          data
        else # Handle old Marshal.dump'd session
          Marshal.load(str)
        end
      else
        raise InvalidSignature
      end
    end
 
    def generate(value)
      data = ActiveSupport::Base64.encode64s(Yajl::Encoder.encode(value))
      "#{data}--#{generate_digest(data)}"
    end
  end
end

# Register the new session backend
module ActionController
  module Session
    # Bad camel-casing is required by Ruby
    class JsonCookieStore < CookieStore
      def verifier_for(secret, digest)
        key = secret.respond_to?(:call) ? secret.call : secret
        ActiveSupport::JSONMessageVerifier.new(key, digest)
      end
    end
  end
end
