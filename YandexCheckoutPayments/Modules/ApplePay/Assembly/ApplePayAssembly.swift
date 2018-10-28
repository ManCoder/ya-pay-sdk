import PassKit
import UIKit

struct ApplePayModuleInputData {
    let merchantIdentifier: String?
    let amount: Amount
    let shopName: String
    let supportedNetworks: [PKPaymentNetwork]
}

enum ApplePayAssembly {

    static func makeModule(inputData: ApplePayModuleInputData,
                           moduleOutput: ApplePayModuleOutput) -> UIViewController? {

        guard PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: inputData.supportedNetworks),
              let merchantIdentifier = inputData.merchantIdentifier,
              let countryCode = Locale.current.regionCode else {
            return nil
        }

        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = merchantIdentifier
        paymentRequest.countryCode = countryCode
        paymentRequest.currencyCode = inputData.amount.currency.rawValue
        paymentRequest.supportedNetworks = inputData.supportedNetworks
        paymentRequest.merchantCapabilities = .capability3DS

        let amountValue = inputData.amount.value as NSDecimalNumber
        let amount = PKPaymentSummaryItem(label: inputData.shopName, amount: amountValue)
        paymentRequest.paymentSummaryItems = [amount]

        let authorizationViewController = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest)
        authorizationViewController?.delegate = moduleOutput

        return authorizationViewController
    }
}
