//= require spree/backend

SpreePaypalExpress = {
  hideSettings: function(paymentMethod) {
    if (SpreePaypalExpress.paymentMethodID && paymentMethod.val() == SpreePaypalExpress.paymentMethodID) {
      $('#payment_amount').prop('disabled', 'disabled');
      $('button[type="submit"]').prop('disabled', 'disabled');
    } else if (SpreePaypalExpress.paymentMethodID) {
      $('button[type=submit]').prop('disabled', '');
      $('#payment_amount').prop('disabled', '')
    }
  }
}

$(document).ready(function() {
  checkedPaymentMethod = $('[data-hook="payment_method_field"] input[type="radio"]:checked');
  SpreePaypalExpress.hideSettings(checkedPaymentMethod);
  paymentMethods = $('[data-hook="payment_method_field"] input[type="radio"]').click(function (e) {
    SpreePaypalExpress.hideSettings($(e.target));
  });
})
