module Pesapal
  class QueryPaymentStatus

    require 'oauth'
    require 'uri'
    require 'active_support/core_ext/object/to_query'
    require 'htmlentities'

    attr_reader :pesapal_merchant_reference, :pesapal_transaction_tracking_id, :token, :test

    HTTP_METHOD = 'get'
    API_ACTION = '/API/QueryPaymentStatus'

    def initialize(pesapal_merchant_reference, pesapal_transaction_tracking_id, test=true)
      @pesapal_merchant_reference   = pesapal_merchant_reference
      @pesapal_transaction_tracking_id    = pesapal_transaction_tracking_id
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
          'pesapal_merchant_reference'       => pesapal_merchant_reference,
          'pesapal_transaction_tracking_id' => pesapal_transaction_tracking_id,
      }
    end

    def params_to_string
      strings = []
      params.each do |key, value|
        strings << "#{key}=#{ERB::Util.url_encode(value)}"
      end
      strings.join('&')
    end
  end
end
