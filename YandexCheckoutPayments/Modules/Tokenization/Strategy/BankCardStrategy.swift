import FunctionalSwift
import PassKit
import YandexCheckoutPaymentsApi

final class BankCardStrategy {
    let paymentOption: PaymentOption

    weak var output: TokenizationStrategyOutput?
    weak var contractStateHandler: ContractStateHandler?
    fileprivate weak var bankCardDataInputModule: BankCardDataInputModuleInput?

    init(paymentOption: PaymentOption) throws {
        guard case .bankCard = paymentOption.paymentMethodType else {
            throw TokenizationStrategyError.incorrectPaymentOptions
        }
        self.paymentOption = paymentOption
    }
}

extension BankCardStrategy: TokenizationStrategyInput {

    func beginProcess() {
        output?.presentContract(paymentOption: paymentOption)
    }

    func didPressSubmitButton(on module: ContractModuleInput) {
        output?.presentBankCardDataInput()
    }

    func bankCardDataInputModule(_ module: BankCardDataInputModuleInput,
                                 didPressConfirmButton bankCardData: CardData) {
        guard let bankCard = makeBankCard(bankCardData) else {
            // TODO: show error
            return
        }
        bankCardDataInputModule = module
        output?.tokenize(.bankCard(bankCard))
    }

    func didPressConfirmButton(on module: BankCardDataInputModuleInput, cvc: String) {
    }

    func didLoginInYandexMoney(_ response: YamoneyLoginResponse) {
    }

    func failLoginInYandexMoney(_ error: Error) {
    }

    func failTokenizeData(_ error: Error) {
        bankCardDataInputModule?.bankCardDidTokenize(error)
    }

    func failResendSmsCode(_ error: Error) {
    }

    func yamoneyAuthParameters(_ module: YamoneyAuthParametersModuleInput,
                               loginWithReusableToken isReusableToken: Bool) {
    }

    func didPressLogout() {
    }

    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didAuthorizePayment payment: PKPayment,
                                            completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
    }

    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
    }

    func sberbankModule(_ module: SberbankModuleInput, didPressConfirmButton phoneNumber: String) { }

    func didFailPresentApplePayModule() { }

    func didPresentApplePayModule() { }
}

private func makeBankCard(_ cardData: CardData) -> BankCard? {
    guard let number = cardData.pan,
          let expiryDateComponents = cardData.expiryDate,
          let expiryYear = String.init -<< expiryDateComponents.year,
          let expiryMonth = String.init -<< expiryDateComponents.month,
          let csc = cardData.csc else {
        return nil
    }
    let bankCard = BankCard(number: number,
                            expiryYear: expiryYear,
                            expiryMonth: makeCorrectExpiryMonth(expiryMonth),
                            csc: csc,
                            cardholder: nil)
    return bankCard
}

private func makeCorrectExpiryMonth(_ month: String) -> String {
    return month.count > 1 ? month : "0" + month
}
