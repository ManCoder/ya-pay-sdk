import Foundation

struct SettingsEntity {

    var isYandexMoneyEnabled = true
    var isBankCardEnabled = true
    var isApplePayEnabled = true
    var isSberbankEnabled = true

    var isShowingYandexLogoEnabled = true

    var price = Decimal(5.0)

    var testModeSettings = TestSettingsEntity()
}
