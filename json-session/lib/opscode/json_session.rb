require 'yajl'
require 'set'
require 'erb'

module Opscode
  module JSONFlashHashImpl
    def initialize(data)
      super()
      used_data = data.delete('used')
      # Force symbolic keys since that is the convention Rails uses
      replace(data.inject({}){|memo, (k, v)| memo[k] = v.html_safe; memo}.symbolize_keys)
      # Repopulate the used data
      if used_data
        @used = used_data.inject(@used.class.new) do |memo, (k, v)|
          k = k.to_sym
          if @used.is_a? Set
            memo.add(k) if v
          else
            memo[k] = v
          end
          memo
        end
      end
    end

    # Work around HashWithIndifferentAccess trying to convert this back (Rails 2 only)
    def with_indifferent_access
      self
    end
  end

  # New message verifier that uses JSON for storage
  class JSONMessageVerifier < ActiveSupport::MessageVerifier
    def verify(signed_message)
      raise InvalidSignature if signed_message.blank?

      data, digest = signed_message.split("--")
      if data.present? && digest.present? && secure_compare(digest, generate_digest(data))
        str = ActiveSupport::Base64.decode64(data)
        if str[0..0] == '{'
          parser = Yajl::Parser.new
          data = parser.parse(str).symbolize_keys
          data['flash'] = Opscode::JSONFlashHash.new(data.delete(:flash)) if data[:flash]
          data
        else # Handle old Marshal.dump'd session
          Marshal.load(str)
        end
      else
        raise InvalidSignature
      end
    end
 
    def generate(value)
      value = value.clone
      if value['flash']
        flash_data = value['flash']
        value['flash'] = flash_data.instance_variable_get(:@flashes) if flash_data.instance_variable_get(:@flashes)
        value['flash']['used'] = flash_data.instance_variable_get(:@used) || {}
        value['flash']['used'].delete 'used'
        if value['flash']['used'].is_a? Set
          value['flash']['used'] = value['flash']['used'].inject({}) {|memo, v| memo[v] = true; memo}
        end
        value['flash'] = value['flash'].inject({}) do |memo, (k, v)|
          if k == 'used'
            memo[k] = v
          else
            memo[k] = ERB::Util::html_escape(v)
          end
          memo
        end
      end
      data = ActiveSupport::Base64.encode64s(Yajl::Encoder.encode(value))
      "#{data}--#{generate_digest(data)}"
    end
  end

end
