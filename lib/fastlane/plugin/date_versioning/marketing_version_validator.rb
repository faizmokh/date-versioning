module Fastlane
  module DateVersioning
    class MarketingVersionValidator
      PATTERN = /\A\d+(?:\.\d+)*\z/

      def self.valid?(value)
        value.is_a?(String) && value.match?(PATTERN)
      end

      def self.validate!(value)
        raise ArgumentError, "Invalid marketing version: #{value}" unless valid?(value)
      end
    end
  end
end
