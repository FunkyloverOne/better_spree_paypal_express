# frozen_string_literal: true

module Spree::Api::V2::EventSubscriptions
  class PaypalPaymentsController < Spree::Api::V2::BaseController
    # alias spree_current_user current_user

    before_action :load_data

    def create
      items = []

      items << {
        Name: "taxes",
        Quantity: 1,
        Amount: {
          currencyID: @subscription.currency,
          value: to_money_amount(@subscription.display_price)
        }
      }
      items << {
        Name: "Event ID:#{@event.id}",
        Quantity: 1,
        Amount: {
          currencyID: @subscription.currency,
          value: to_money_amount(@subscription.display_additional_tax_total || 0)
        }
      }

      items.reject! { |item| item[:Amount][:value].zero? }

      pp_request = provider.build_set_express_checkout(express_checkout_request_details(items))

      # Trying to confirm to https://guides.spreecommerce.com/api/summary.html
      # as much as possible
      begin
        pp_response = provider.set_express_checkout(pp_request)
        if pp_response.success?
          url = provider.express_checkout_url(pp_response, useraction: 'commit')
          render json: { redirect_url: url }, status: 200
        else
          # this one is easy we can just respond with pp_response errors
          render json: { errors: pp_response.errors.collect(&:long_message).join(' ') }, status: 422
        end
      rescue SocketError
        render json: { errors: [Spree.t('flash.connection_failed', scope: 'paypal')] }, status: 500
      end
    end

    def confirm
      @subscription.payments.create!(
        {
          source: Spree::PaypalExpressCheckout.create(
            { token: params[:token], payer_id: params[:PayerID] }
          ),
          amount: to_money_amount(@subscription.display_total),
          payment_method: payment_method
        }
      )
      render json: @subscription.to_json, status: 200
    end

    private

    def to_money_amount(object)
      case object
      when Spree::Money then object.money.amount
      when ::Money then object.amount
      when 0 then object
      else raise  ArgumentError,
                  "#{object} is not of supported class for money amount"
      end
    end

    def express_checkout_request_details(items)
      { SetExpressCheckoutRequestDetails: {
        InvoiceID: @subscription.number,
        BuyerEmail: @subscription.email || @subscription.user.email,
        # Here we tell paypal redirect to client and have the client post back status to rails server
        ReturnURL: confirm_url,
        CancelURL: cancel_url,
        SolutionType: payment_method.preferred_solution.present? ? payment_method.preferred_solution : 'Mark',
        LandingPage: payment_method.preferred_landing_page.present? ? payment_method.preferred_landing_page : 'Billing',
        cppheaderimage: payment_method.preferred_logourl.present? ? payment_method.preferred_logourl : '',
        NoShipping: 1,
        PaymentDetails: [payment_details(items)]
      } }
    end

    def payment_method
      Spree::PaymentMethod.find(
        request.headers['X-Spree-Payment-Method-Id'] ||
        params[:payment_method_id]
      )
    end

    def provider
      payment_method.provider
    end

    def payment_details(items)
      {
        OrderTotal: {
          currencyID: @subscription.currency,
          value: to_money_amount(@subscription.display_total)
        },
        ItemTotal: {
          currencyID: @subscription.currency,
          value: to_money_amount(@event.display_price)
        },
        TaxTotal: {
          currencyID: @subscription.currency,
          value:
            to_money_amount(@subscription.display_additional_tax_total)
        },
        PaymentAction: 'Sale'
      }
    end

    def load_data
      @event = Event.find(params[:event_id])
      @subscription = @event.subscriptions.find_by(user: spree_current_user)
    end

    def confirm_url
      params.require(:confirm_url) # TODO: check allowed links
    end

    def cancel_url
      params.require(:cancel_url) # TODO: check allowed links
    end
  end
end
