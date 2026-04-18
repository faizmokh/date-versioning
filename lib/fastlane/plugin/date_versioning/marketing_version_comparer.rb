module Fastlane
  module DateVersioning
    class MarketingVersionComparer
      def self.compare(left, right)
        left_parts = normalize(left)
        right_parts = normalize(right)
        length = [left_parts.length, right_parts.length].max

        length.times do |index|
          comparison = (left_parts[index] || 0) <=> (right_parts[index] || 0)
          return comparison unless comparison.zero?
        end

        0
      end

      def self.normalize(value)
        MarketingVersionValidator.validate!(value)
        value.split('.').map(&:to_i)
      end
      private_class_method :normalize
    end
  end
end
