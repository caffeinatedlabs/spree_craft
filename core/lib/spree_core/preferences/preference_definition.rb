# Most of this code is from the preferences plugin available at
# http://github.com/pluginaweek/preferences/tree/master
#
module Spree
  # Adds support for defining preferences on ActiveRecord models.
  module Preferences
    # Represents the definition of a preference for a particular model
    class PreferenceDefinition
      def initialize(name, *args) #:nodoc:
        options = args.extract_options!
        options.assert_valid_keys(:default)

        @name = name.to_s
        @type = args.first ? args.first.to_s.camelize : 'Boolean'
        @default = options[:default]
      end

      # The attribute which is being preferenced
      def name
        @name
      end

      # The default value to use for the preference in case none have been
      # previously defined
      def default_value
        @default
      end

      # Typecasts the value based on the type of preference that was defined
      def type_cast(value)
        if @type == 'Any'
          value
        else
          ActiveRecord::Type.const_get(@type).new.send :cast_value, value
        end
      end

      # Typecasts the value to true/false depending on the type of preference
      def query(value)
        unless value = type_cast(value)
          false
        else
          if value.is_a?(Numeric)
            !value.zero?
          else
            !value.blank?
          end
        end
      end
    end
  end
end
