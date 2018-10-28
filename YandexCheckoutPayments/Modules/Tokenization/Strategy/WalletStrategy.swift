import FunctionalSwift
import YandexCheckoutPaymentsApi
import struct YandexCheckoutWalletApi.AuthTypeState
import PassKit

final class WalletStrategy {
    let authorizationService: AuthorizationProcessing
    let paymentOption: PaymentInstrumentYandexMoneyWallet

    weak var output: TokenizationStrategyOutput?
    weak var contractStateHandler: ContractStateHandler?

    init(authorizationService: AuthorizationProcessing,
         paymentOption: PaymentOption) throws {
        guard let paymentOption = paymentOption as? PaymentInstrumentYandexMoneyWallet else {
            throw TokenizationStrategyError.incorrectPaymentOptions
        }
        self.paymentOption = paymentOption
        self.authorizationService = authorizationService
    }
}

extension WalletStrategy: TokenizationStrategyInput {

    func beginProcess() {
        if authorizationService.hasReusableYamoneyToken() {
            output?.presentContract(paymentOption: paymentOption)
        } else {
            output?.presentYamoneyAuthParametersModule(paymentOption: paymentOption)
        }
    }

    func didPressSubmitButton(on module: ContractModuleInput) {

        contractStateHandler = module
        module.hidePlaceholder()
        module.showActivity()

        output?.tokenize(.wallet)
    }

    func yamoneyAuthParameters(_ module: YamoneyAuthParametersModuleInput,
                               loginWithReusableToken isReusableToken: Bool) {

        contractStateHandler = module
        module.hidePlaceholder()
        module.showActivity()

        output?.loginInYandexMoney(reusableToken: isReusableToken)
    }

    func didLoginInYandexMoney(_ response: YamoneyLoginResponse) {
        switch response {
        case .authorized:
            output?.tokenize(.wallet)
        case let .notAuthorized(authTypeState: authTypeState, processId: processId, authContextId: authContextId):
            output?.presentYamoneyAuthModule(paymentOption: paymentOption,
                                             processId: processId,
                                             authContextId: authContextId,
                                             authTypeState: authTypeState)
        }
    }

    func failLoginInYandexMoney(_ error: Error) {
        contractStateHandler?.failLoginInYandexMoney(error)
    }

    func failTokenizeData(_ error: Error) {
        contractStateHandler?.failTokenizeData(error)
    }

    func failResendSmsCode(_ error: Error) {
        contractStateHandler?.failResendSmsCode(error)
    }

    func bankCardDataInputModule(_ module: BankCardDataInputModuleInput,
                                 didPressConfirmButton bankCardData: CardData) {}

    func didPressConfirmButton(on module: BankCardDataInputModuleInput, cvc: String) {}

    func didPressLogout() {
        output?.logout(accountId: paymentOption.accountId)
    }

    func sberbankModule(_ module: SberbankModuleInput, didPressConfirmButton phoneNumber: String) { }

    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didAuthorizePayment payment: PKPayment,
                                            completion: @escaping (PKPaymentAuthorizationStatus) -> Void) { }

    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) { }

    func didFailPresentApplePayModule() { }

    func didPresentApplePayModule() { }
}
