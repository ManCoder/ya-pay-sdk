import YandexMobileMetrica

final class AnalyticsService: AnalyticsProcessing {

    #if DEBUG
    private let yandexMetricaKey = "4f547440-406e-4734-81f4-bb695ef8e3fc"
    #else
    private let yandexMetricaKey = "b1ddbdc0-dca6-489c-a205-f71e0158bfcb"
    #endif

    private lazy var reporter: YMMYandexMetricaReporting? =
        YMMYandexMetrica.reporter(forApiKey: yandexMetricaKey)

    func start() {
        reporter?.resumeSession()
    }

    func stop() {
        reporter?.pauseSession()
    }

    func trackEvent(_ event: AnalyticsEvent) {
        let eventName = makeAnalyticsEventName(event)
        let parameters = makeAnalyticsParameters(event)
        trackEventNamed(eventName, parameters: parameters)
    }

    func trackEventNamed(_ name: String, parameters: [String: String]?) {
        logAnalyticsEventNamed(name, parameters: parameters)
        reporter?.reportEvent(name, parameters: parameters)
    }

    // swiftlint:disable cyclomatic_complexity
    private func makeAnalyticsEventName(_ event: AnalyticsEvent) -> String {
        let eventName: String

        switch event {
        case .screenPaymentOptions:
            eventName = EventKey.screenPaymentOptions.rawValue
        case .screenPaymentContract:
            eventName = EventKey.screenPaymentContract.rawValue
        case .screenLinkedCardForm:
            eventName = EventKey.screenLinkedCardForm.rawValue
        case .screenBankCardForm:
            eventName = EventKey.screenBankCardForm.rawValue
        case .screenError:
            eventName = EventKey.screenError.rawValue
        case .screen3ds:
            eventName = EventKey.screen3ds.rawValue
        case .actionTokenize:
            eventName = EventKey.actionTokenize.rawValue
        case .actionYaLoginAuthorization:
            eventName = EventKey.actionYaLoginAuthorization.rawValue
        case .actionPaymentAuthorization:
            eventName = EventKey.actionPaymentAuthorization.rawValue
        case .actionLogout:
            eventName = EventKey.actionLogout.rawValue
        case .actionChangePaymentMethod:
            eventName = EventKey.actionChangePaymentMethod.rawValue
        case .actionAuthWithoutWallet:
            eventName = EventKey.actionAuthWithoutWallet.rawValue
}
        return eventName
    }
    // swiftlint:enable cyclomatic_complexity

    // swiftlint:disable cyclomatic_complexity
    private func makeAnalyticsParameters(_ event: AnalyticsEvent) -> [String: String]? {
        var parameters: [String: String]?

        switch event {
        case .screenPaymentOptions(let authType):
            parameters = [
                authType.key: authType.rawValue,
            ]

        case .screenPaymentContract(let authType, let scheme):
            parameters = [
                authType.key: authType.rawValue,
                scheme.key: scheme.rawValue,
            ]

        case .screenLinkedCardForm:
            parameters = nil

        case .screenBankCardForm(let authType):
            parameters = [
                authType.key: authType.rawValue,
            ]

        case .screenError(let authType, let scheme):
            parameters = [
                authType.key: authType.rawValue,
            ]
            if let scheme = scheme {
                parameters?[scheme.key] = scheme.rawValue
            }

        case .screen3ds:
            parameters = nil

        case .actionTokenize(let scheme, let authType, let tokenType):
            parameters = [
                scheme.key: scheme.rawValue,
                authType.key: authType.rawValue,
            ]
            if let tokenType = tokenType {
                parameters?[tokenType.key] = tokenType.rawValue
            }

        case .actionYaLoginAuthorization(let loginStatus):
            parameters = [
                loginStatus.key: loginStatus.rawValue,
            ]

        case .actionPaymentAuthorization(let authStatus):
            parameters = [
                authStatus.key: authStatus.rawValue,
            ]

        case .actionLogout:
            parameters = nil

        case .actionChangePaymentMethod:
            parameters = nil

        case .actionAuthWithoutWallet:
            parameters = nil
        }

        return parameters
    }
    // swiftlint:enable cyclomatic_complexity

    private enum EventKey: String {
        case screenPaymentOptions
        case screenPaymentContract
        case screenLinkedCardForm
        case screenBankCardForm
        case screenError
        case screen3ds
        case actionTokenize
        case actionYaLoginAuthorization
        case actionPaymentAuthorization
        case actionLogout
        case actionChangePaymentMethod
        case actionAuthWithoutWallet
    }
}

private func logAnalyticsEventNamed(_ name: String, parameters: [String: String]?) {
    #if DEBUG
    guard let parameters = parameters else {
        print("YandexMetrica event name: \(name)")
        return
    }
    print("YandexMetrica event name: \(name), parameters: \(parameters)")
    #endif
}
