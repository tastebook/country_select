# CountrySelect
#
# Adds #country_select method to
# ActionView::FormBuilder
#
require 'country_select/version'
require 'country_select/country_codes'

module ActionView
  module Helpers
    module FormOptionsHelper
      #
      # Return select and option tags
      # for the given object and method,
      # using country_options_for_select to
      # generate the list of option tags.
      #
      def country_select(object, method, priority_countries = nil,
                                         options = {},
                                         html_options = {})

        tag = if defined?(ActionView::Helpers::InstanceTag) &&
                ActionView::Helpers::InstanceTag.instance_method(:initialize).arity != 0

                InstanceTag.new(object, method, self, options.delete(:object))
              else
                CountrySelect.new(object, method, self, options)
              end

        tag.to_country_select_tag(priority_countries, options, html_options)
      end

      #
      # Returns a string of option tags for
      # pretty much any country in the world.
      # Supply a country name as +selected+ to
      # have it marked as the selected option tag.
      #
      # You can also supply an array of countries as
      # +priority_countries+ so that they will be
      # listed above the rest of the (long) list.
      #
      # NOTE: Only the option tags are returned, you
      # have to wrap this call in a regular HTML
      # select tag.
      #
      def country_options_for_select(selected = nil, priority_countries = nil)
        country_options = "".html_safe

        if priority_countries
          country_options += options_for_select(priority_countries, selected)
          country_options += "<option value=\"\" disabled=\"disabled\">-------------</option>\n".html_safe
          #
          # prevents selected from being included
          # twice in the HTML which causes
          # some browsers to select the second
          # selected option (not priority)
          # which makes it harder to select an
          # alternative priority country
          #
          selected = nil if priority_countries.include?(selected)
        end

        return country_options + options_for_select(COUNTRIES, selected)
      end

      # All the countries included in the country_options output.
      CountryCodes.load_countries_from_yaml
      COUNTRIES = (CountryCodes.countries_for_select('name', 'a2') - 
                   [["Indonesia", "ID"],["Ghana", "GH"],["Nigeria", "NG"], ["Antartica", "AQ"], ["Puerto Rico", "PR"]]).sort
    end

    module ToCountrySelectTag
      def to_country_select_tag(priority_countries, options, html_options)
        html_options = html_options.stringify_keys
        add_default_name_and_id(html_options)
        value = value(object)
        content_tag("select",
          add_options(
            country_options_for_select(value, priority_countries),
            options, value
          ), html_options
        )
      end
    end

    if defined?(ActionView::Helpers::InstanceTag) &&
        ActionView::Helpers::InstanceTag.instance_method(:initialize).arity != 0
      class InstanceTag
        include ToCountrySelectTag
      end
    else
      class CountrySelect < Tags::Base
        include ToCountrySelectTag
      end
    end

    class FormBuilder
      def country_select(method, priority_countries = nil,
                                 options = {},
                                 html_options = {})

        @template.country_select(@object_name, method, priority_countries,
                                                       options.merge(:object => @object),
                                                       html_options)
      end
    end
  end
end
