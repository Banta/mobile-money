module Pesapal
  class OrderUrl

    require 'oauth'
    require 'uri'
    require 'active_support/core_ext/object/to_query'
    require 'htmlentities'

    attr_reader :post_data_xml, :callback_url, :token, :test

    HTTP_METHOD = 'get'
    API_ACTION = '/API/PostPesapalDirectOrderV4'

    def initialize(data={}, callback_url, test=true)
      line_items = ""

      if data[:line_items].count > 0
        data[:line_items].each do |line_item|
          line_items << %Q[<lineitem uniqueid="#{line_item[:id]}"
                              particulars="#{line_item[:name]}"
                              quantity="#{line_item[:quantity] || '1'}"
                              unitcost="#{line_item[:unit_cost]}"
                              subtotal="#{line_item[:sub_total]}">
                            </lineitem>]
        end
      end
      data_xml = %[<?xml version="1.0" encoding="utf-8"?>
<PesapalDirectOrderInfo
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:xsd="http://www.w3.org/2001/XMLSchema"

        Amount="#{data[:amount]}" Currency="#{data[:currency] || 'USD'}"
        Description="#{data[:description]}" Type="#{data[:merchant] ||'MERCHANT'}" Reference="#{data[:reference]}"
        FirstName="#{data[:first_name]}" LastName="#{data[:last_name]}" Email="#{data[:email]}" PhoneNumber="#{data[:phone]}"
        xmlns="http://www.pesapal.com">
  <lineitems>
    #{line_items}
  </lineitems>
</PesapalDirectOrderInfo>]


      @post_data_xml   = data_xml
      @callback_url    = callback_url
      @token           = nil
      @test            = test
    end

    def api_domain
      test ? 'http://demo.pesapal.com' : 'https://www.pesapal.com'
    end

    def url
      "#{api_domain}#{signed_request.path}"
    end

    def consumer
      @consumer ||= begin
        OAuth::Consumer.new(consumer_key, consumer_secret, {
            site: api_domain,
            http_method: HTTP_METHOD,
            scheme: :query_string
        })
      end
    end

    def consumer_key
      Rails.application.secrets.pesapal_consumer_key
    end

    def consumer_secret
      Rails.application.secrets.pesapal_consumer_secret
    end

    def signed_request
      consumer.create_signed_request HTTP_METHOD, request_url, nil, {}, params
    end

    def request_url
      API_ACTION + "?" + params_to_string
    end


    def params
      @params ||= {
          'oauth_callback'       => callback_url,
          'pesapal_request_data' => escaped_xml,
      }
    end

    def params_to_string
      strings = []
      params.each do |key, value|
        strings << "#{key}=#{CGI::escape(value)}"
      end
      strings.join('&')
    end

    def escaped_xml
      HTMLEntities.new.encode(post_data_xml)
    end
  end

end
