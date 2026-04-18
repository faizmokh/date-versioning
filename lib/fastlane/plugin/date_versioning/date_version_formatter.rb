require 'tzinfo'

module Fastlane
  module DateVersioning
    class DateVersionFormatter
      def self.call(timezone:, now: Time.now.utc)
        current_time = if timezone == 'UTC'
                         now.getutc
                       else
                         TZInfo::Timezone.get(timezone).to_local(now.getutc)
                       end

        "#{current_time.year}.#{current_time.month}.#{current_time.day}"
      rescue TZInfo::InvalidTimezoneIdentifier
        raise ArgumentError, "Invalid timezone: #{timezone}"
      end
    end
  end
end
