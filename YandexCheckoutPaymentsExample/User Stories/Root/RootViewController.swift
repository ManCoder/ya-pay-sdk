import MessageUI
import SafariServices
import UIKit
import WebKit
import YandexCheckoutPayments
import YandexCheckoutPaymentsApi

final class RootViewController: UIViewController {

    public static func makeModule() -> UIViewController {
        return RootViewController(nibName: nil, bundle: nil)
    }

    // MARK: - CardScanningDelegate

    weak var cardScanningDelegate: CardScanningDelegate?

    // MARK: - UI properties

    fileprivate lazy var payButton: UIButton = {
        $0.setStyles(UIButton.DynamicStyle.primary)
        $0.setStyledTitle(translate(Localized.buy), for: .normal)
        $0.addTarget(self, action: #selector(payButtonDidPress), for: .touchUpInside)
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIButton(type: .custom))

    fileprivate lazy var favoriteButton: UIButton = {
        $0.setImage(#imageLiteral(resourceName: "Root.Favorite"), for: .normal)
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        return $0
    }(UIButton(type: .custom))

    fileprivate lazy var priceInputViewController: PriceInputViewController = {
        $0.initialPrice = settings.price
        $0.delegate = self
        return $0
    }(PriceInputViewController())

    fileprivate lazy var priceTitleLabel: UILabel = {
        $0.setStyles(UILabel.DynamicStyle.body)
        $0.styledText = translate(Localized.price)
        return $0
    }(UILabel())

    fileprivate lazy var ratingLabel: UILabel = {
        $0.setStyles(UILabel.DynamicStyle.body)
        $0.styledText = "5"
        return $0
    }(UILabel())

    fileprivate lazy var descriptionLabel: UILabel = {
        $0.setStyles(UILabel.DynamicStyle.body,
                     UILabel.Styles.multiline)
        $0.styledText = translate(Localized.description)
        return $0
    }(UILabel())

    fileprivate lazy var nameLabel: UILabel = {
        if #available(iOS 11.0, *) {
            $0.setStyles(UILabel.DynamicStyle.title1)
        } else if #available(iOS 9.0, *) {
            $0.setStyles(UILabel.DynamicStyle.title2)
        } else {
            $0.setStyles(UILabel.DynamicStyle.headline1)
        }
        $0.appendStyle(UILabel.Styles.multiline)
        $0.styledText = translate(Localized.name)
        return $0
    }(UILabel())

    fileprivate lazy var scrollView: UIScrollView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.showsVerticalScrollIndicator = false
        $0.setStyles(UIScrollView.Styles.interactiveKeyboardDismissMode)
        return $0
    }(UIScrollView())

    fileprivate lazy var contentView: UIView = {
        $0.setStyles(UIView.Styles.defaultBackground)
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIView())

    fileprivate lazy var imageView = UIImageView(image: #imageLiteral(resourceName: "Root.Comet"))

    fileprivate lazy var settingsBarItem = UIBarButtonItem(image: #imageLiteral(resourceName: "Root.Settings"),
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(settingsButtonDidPress))

    fileprivate lazy var ratingImageView = UIImageView(image: #imageLiteral(resourceName: "Root.Rating"))

    fileprivate lazy var payButtonBottomConstraint: NSLayoutConstraint =
        self.bottomLayoutGuide.top.constraint(equalTo: payButton.bottom)

    fileprivate lazy var nameLabelTopConstraint: NSLayoutConstraint =
        nameLabel.top.constraint(equalTo: imageView.bottom)

    fileprivate var variableConstraints: [NSLayoutConstraint] = []

    // MARK: - Private properties

    private lazy var settings: SettingsEntity = {
        if let settings = settingsService.loadSettingsFromStorage() {
            return settings
        } else {
            let settings = SettingsEntity()
            settingsService.saveSettingsToStorage(settings: settings)

            return settings
        }
    }()

    private let settingsService: SettingsService

    private var currentKeyboardOffset: CGFloat = 0

    // MARK: - Data properties

    var token: Tokens?
    var paymentMethodType: PaymentMethodType?

    // MARK: - Initialization/Deinitialization

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let keyValueStorage = UserDefaultsStorage(userDefault: UserDefaults.standard)
        settingsService = SettingsService(storage: keyValueStorage)

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        addChildViewController(priceInputViewController)
    }

    required init?(coder aDecoder: NSCoder) {
        let keyValueStorage = UserDefaultsStorage(userDefault: UserDefaults.standard)
        settingsService = SettingsService(storage: keyValueStorage)

        super.init(coder: aDecoder)

        addChildViewController(priceInputViewController)
    }

    deinit {
        unsubscribeFromNotifications()
    }

    // MARK: - Managing the View

    override func loadView() {
        view = UIView()
        view.setStyles(UIView.Styles.defaultBackground)

        loadSubviews()
        loadConstraints()

        priceInputViewController.didMove(toParentViewController: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true

        subscribeOnNotifications()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startKeyboardObserving()
    }

    override open func viewWillDisappear(_ animated: Bool) {
        stopKeyboardObserving()
        super.viewWillDisappear(animated)
    }

    private func loadSubviews() {
        view.addSubview(scrollView)
        view.addSubview(payButton)
        navigationItem.rightBarButtonItem = settingsBarItem
        scrollView.addSubview(contentView)

        let views: [UIView] = [
            priceTitleLabel,
            priceInputViewController.view,
            ratingImageView,
            ratingLabel,
            descriptionLabel,
            nameLabel,
            favoriteButton,
            imageView,
        ]

        views.forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(subview)
        }

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                 action: #selector(rootViewPressed))
        view.addGestureRecognizer(tap)
    }

    private func loadConstraints() {

        let constraints: [NSLayoutConstraint] = [
            scrollView.leading.constraint(equalTo: view.leading),
            scrollView.top.constraint(equalTo: view.top),
            scrollView.trailing.constraint(equalTo: view.trailing),
            payButton.top.constraint(equalTo: scrollView.bottom, constant: Space.quadruple),

            scrollView.leading.constraint(equalTo: contentView.leading),
            scrollView.top.constraint(equalTo: contentView.top),
            scrollView.trailing.constraint(equalTo: contentView.trailing),
            scrollView.bottom.constraint(equalTo: contentView.bottom),
            contentView.width.constraint(equalTo: view.width),

            payButton.leading.constraint(equalTo: contentView.leadingMargin),
            payButton.trailing.constraint(equalTo: contentView.trailingMargin),
            payButtonBottomConstraint,

            priceTitleLabel.leading.constraint(equalTo: contentView.leadingMargin),
            contentView.trailingMargin.constraint(equalTo: priceInputViewController.view.trailing),
            contentView.bottom.constraint(equalTo: priceInputViewController.view.bottom),

            ratingImageView.leading.constraint(equalTo: contentView.leadingMargin),
            ratingLabel.leading.constraint(equalTo: ratingImageView.trailing, constant: Space.single),
            ratingLabel.centerY.constraint(equalTo: ratingImageView.centerY),

            descriptionLabel.leading.constraint(equalTo: contentView.leadingMargin),
            contentView.trailingMargin.constraint(equalTo: descriptionLabel.trailing),
            ratingImageView.top.constraint(equalTo: descriptionLabel.bottom, constant: Space.double),
            descriptionLabel.trailing.constraint(equalTo: contentView.trailingMargin),

            nameLabel.leading.constraint(equalTo: contentView.leadingMargin),
            descriptionLabel.top.constraint(equalTo: nameLabel.bottom, constant: Space.single),

            favoriteButton.leading.constraint(equalTo: nameLabel.trailing, constant: Space.double),
            contentView.trailingMargin.constraint(equalTo: favoriteButton.trailing),
            favoriteButton.centerY.constraint(equalTo: nameLabel.centerY),

            imageView.leading.constraint(equalTo: contentView.leadingMargin),
            contentView.trailingMargin.constraint(equalTo: imageView.trailing),
            imageView.top.constraint(equalTo: contentView.topMargin),
            imageView.height.constraint(equalTo: imageView.width, multiplier: 1),
            nameLabelTopConstraint,
        ]

        NSLayoutConstraint.activate(constraints)

        updateVariableConstraints()
    }

    @objc
    private func accessibilityReapply() {
        payButton.setStyledTitle(translate(Localized.buy), for: .normal)
        ratingLabel.styledText = "5"
        descriptionLabel.styledText = translate(Localized.description)
        nameLabel.styledText = translate(Localized.name)
        priceTitleLabel.styledText = priceTitleLabel.styledText

        updateVariableConstraints()
    }

    private func updatePayButtonBottomConstraint() {
        view.layoutIfNeeded()
        UIView.animate(withDuration: CATransaction.animationDuration()) {
            if self.traitCollection.horizontalSizeClass == .regular {
                self.payButtonBottomConstraint.constant = Space.fivefold + self.currentKeyboardOffset
            } else {
                self.payButtonBottomConstraint.constant = Space.double + self.currentKeyboardOffset
            }
            self.view.layoutIfNeeded()
        }
    }

    private func updateVariableConstraints() {
        NSLayoutConstraint.deactivate(variableConstraints)

        if UIApplication.shared.preferredContentSizeCategory.isAccessibilitySizeCategory {
            variableConstraints = [
                priceTitleLabel.trailing.constraint(equalTo: contentView.trailing),
                priceInputViewController.view.leading.constraint(equalTo: contentView.leadingMargin),
                priceTitleLabel.bottom.constraint(equalTo: priceInputViewController.view.top, constant: 0),
                priceTitleLabel.top.constraint(equalTo: ratingImageView.bottom, constant: Space.double),
            ]
        } else {
            variableConstraints = [
                priceTitleLabel.trailing.constraint(equalTo: priceInputViewController.view.leading),
                priceInputViewController.view.width
                    .constraint(greaterThanOrEqualToConstant: Constants.priceInputMinWidth),
                priceTitleLabel.top.constraint(equalTo: priceInputViewController.view.top,
                                               constant: Constants.priceTitleLabelTopOffset),
                priceInputViewController.view.top.constraint(equalTo: ratingImageView.bottom),
            ]
        }

        NSLayoutConstraint.activate(variableConstraints)
    }

    // MARK: - Actions

    @objc
    private func payButtonDidPress() {

        guard let price = priceInputViewController.price else {
            return
        }

        token = nil
        paymentMethodType = nil

        priceInputViewController.view.endEditing(true)

        settings.price = price
        settingsService.saveSettingsToStorage(settings: settings)

        let testSettings: TestModeSettings?

        if settings.testModeSettings.isTestModeEnadled {
            let testAmount = MonetaryAmount(value: settings.price,
                                            currency: .rub)

            let paymentAuthorizationPassed = settings.testModeSettings.isPaymentAuthorizationPassed
            testSettings = TestModeSettings(paymentAuthorizationPassed: paymentAuthorizationPassed,
                                            cardsCount: settings.testModeSettings.cardsCount ?? 0,
                                            charge: testAmount,
                                            enablePaymentError: settings.testModeSettings.isPaymentWithError)
        } else {
            testSettings = nil
        }

        let amount = Amount(value: settings.price, currency: .rub)
        let oauthToken = "live_MTkzODU2VY5GiyQq2GMPsCQ0PW7f_RSLtJYOT-mp_CA"
        let inputData = TokenizationModuleInputData(clientApplicationKey: oauthToken,
                                                    shopName: translate(Localized.name),
                                                    purchaseDescription: translate(Localized.description),
                                                    amount: amount,
                                                    tokenizationSettings: makeTokenizationSettings(),
                                                    testModeSettings: testSettings,
                                                    cardScanning: self,
                                                    applePayMerchantIdentifier: "merchant.ru.yandex.mobile.msdk.debug")
        let viewController = TokenizationAssembly.makeModule(inputData: inputData,
                                                             moduleOutput: self)
        present(viewController, animated: true, completion: nil)
    }

    @objc
    private func settingsButtonDidPress() {
        priceInputViewController.view.endEditing(true)

        let module = SettingsViewController.makeModule(settings: settings, delegate: self)
        let navigation = UINavigationController(rootViewController: module)

        if #available(iOS 11.0, *) {
            navigation.navigationBar.prefersLargeTitles = true
        }

        present(navigation, animated: true, completion: nil)
    }

    @objc
    private func rootViewPressed() {
        view.endEditing(true)
    }

    // MARK: - Notifications

    private func subscribeOnNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(accessibilityReapply),
                                               name: .UIContentSizeCategoryDidChange,
                                               object: nil)
    }

    private func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Responding to a Change in the Interface Environment

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.horizontalSizeClass == .regular {
            payButtonBottomConstraint.constant = Space.fivefold
            nameLabelTopConstraint.constant = Constants.nameTopOffset * 2
            contentView.layoutMargins = UIEdgeInsets(top: Space.quadruple,
                                                     left: view.frame.width * Constants.widthRatio,
                                                     bottom: 0,
                                                     right: view.frame.width * Constants.widthRatio)
        } else {
            payButtonBottomConstraint.constant = Space.double
            nameLabelTopConstraint.constant = Constants.nameTopOffset
            contentView.layoutMargins = UIEdgeInsets(top: Space.single,
                                                     left: Space.double,
                                                     bottom: 0,
                                                     right: Space.double)
        }

        updatePayButtonBottomConstraint()
    }

    // MARK: - Data making

    private func makeTokenizationSettings() -> TokenizationSettings {
        var paymentTypes: PaymentMethodTypes = []

        if settings.isBankCardEnabled {
            paymentTypes.insert(.bankCard)
        }
        if settings.isYandexMoneyEnabled {
            paymentTypes.insert(.yandexMoney)
        }
        if settings.isApplePayEnabled {
            paymentTypes.insert(.applePay)
        }
        if settings.isSberbankEnabled {
            paymentTypes.insert(.sberbank)
        }

        return TokenizationSettings(paymentMethodTypes: paymentTypes,
                                    showYandexCheckoutLogo: settings.isShowingYandexLogoEnabled)
    }
}

extension RootViewController: SettingsViewControllerDelegate {
    func settingsViewController(_ settingsViewController: SettingsViewController,
                                didChangeSettings settings: SettingsEntity) {

        self.settings = settings
        settingsService.saveSettingsToStorage(settings: settings)
    }
}

// MARK: - TokenizationModuleOutput
extension RootViewController: TokenizationModuleOutput {
    func tokenizationModule(_ module: TokenizationModuleInput,
                            didTokenize token: Tokens,
                            paymentMethodType: PaymentMethodType) {

        self.token = token
        self.paymentMethodType = paymentMethodType

        let successViewController = SuccessViewController()
        successViewController.delegate = self

        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            if let presentedViewController = strongSelf.presentedViewController {
                presentedViewController.show(successViewController, sender: self)
            } else {
                strongSelf.present(successViewController, animated: true)
            }
        }
    }

    func didFinish(on module: TokenizationModuleInput) {

        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.dismiss(animated: true)
        }
    }

    func didSuccessfullyPassedCardSec(on module: TokenizationModuleInput) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            let alertController = UIAlertController(title: "3D-Sec",
                                                    message: "Successfully passed 3d-sec",
                                                    preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default)
            alertController.addAction(action)
            strongSelf.dismiss(animated: true)
            strongSelf.present(alertController, animated: true)
        }
    }
}

// MARK: - Keyboard Observing

extension RootViewController {

    func startKeyboardObserving() {

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: .UIKeyboardWillShow,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: .UIKeyboardWillHide,
                                               object: nil)
    }

    func stopKeyboardObserving() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardEndFrame = makeKeyboardEndFrame(from: notification) else { return }
        currentKeyboardOffset = keyboardYOffset(from: keyboardEndFrame) ?? 0
        updatePayButtonBottomConstraint()
    }

    @objc
    private func keyboardWillHide(_ notification: Notification) {
        guard let keyboardEndFrame = makeKeyboardEndFrame(from: notification) else { return }
        currentKeyboardOffset = keyboardYOffset(from: keyboardEndFrame) ?? 0
        updatePayButtonBottomConstraint()
    }

    private func makeKeyboardEndFrame(from notification: Notification) -> CGRect? {
        let userInfo = notification.userInfo
        let endFrameValue = userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue
        let endFrame = endFrameValue.map { $0.cgRectValue }
        return endFrame
    }

    private func keyboardYOffset(from keyboardFrame: CGRect) -> CGFloat? {
        let convertedKeyboardFrame = view.convert(keyboardFrame, from: nil)
        let intersectionViewFrame = convertedKeyboardFrame.intersection(view.bounds)
        var safeOffset: CGFloat = 0
        if #available(iOS 11.0, *) {
            let intersectionSafeFrame = convertedKeyboardFrame.intersection(view.safeAreaLayoutGuide.layoutFrame)
            safeOffset = intersectionViewFrame.height - intersectionSafeFrame.height
        }
        let intersectionOffset = intersectionViewFrame.size.height
        guard convertedKeyboardFrame.minY.isInfinite == false else {
            return nil
        }
        let keyboardOffset = intersectionOffset + safeOffset
        return keyboardOffset
    }
}

extension RootViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true)
    }
}

extension RootViewController: PriceInputViewControllerDelegate {
    func priceInputViewController(_ priceInputViewController: PriceInputViewController,
                                  didChangePrice price: Decimal?,
                                  valid: Bool) {

        if price != nil, valid == true {
            payButton.isEnabled = true
        } else {
            payButton.isEnabled = false
        }

        scrollView.scrollRectToVisible(priceInputViewController.view.frame,
                                       animated: true)
    }
}

// MARK: - SuccessViewControllerDelegate

extension RootViewController: SuccessViewControllerDelegate {
    func didPressDocumentationButton(on successViewController: SuccessViewController) {
        dismiss(animated: true) { [weak self] in
            guard let strongSelf = self,
                  let url = URL(string: Constants.documentationPath) else {
                return
            }
            if #available(iOS 9.0, *) {
                let viewController = SFSafariViewController(url: url)
                if #available(iOS 11, *) {
                    viewController.dismissButtonStyle = .close
                }
                strongSelf.present(viewController, animated: true)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }

    func didPressSendTokenButton(on successViewController: SuccessViewController) {
        guard let token = token, let paymentMethodType = paymentMethodType else {
            assertionFailure("Missing token or paymentMethodType")
            return
        }
        let message = """
                Token: \(token.paymentToken)
                Payment method: \(paymentMethodType.rawValue)
            """

        dismiss(animated: true) { [weak self] in
            guard let strongSelf = self else { return }

            let viewController: UIViewController

            if MFMailComposeViewController.canSendMail() == false {
                let alertController = UIAlertController(title: "Token",
                                                        message: message,
                                                        preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default)
                alertController.addAction(action)
                viewController = alertController
            } else {
                let mailController = MFMailComposeViewController()

                mailController.mailComposeDelegate = strongSelf
                mailController.setSubject("iOS App: Payment Token")
                mailController.setMessageBody(message, isHTML: false)

                viewController = mailController
            }

            strongSelf.present(viewController, animated: true)
        }
    }

    func didPressClose(on successViewController: SuccessViewController) {
        dismiss(animated: true)
    }
}

private extension RootViewController {
    enum Localized: String {
        case price = "root.price"
        case buy = "root.buy"
        case description = "root.description"
        case name = "root.name"
    }
}

private extension RootViewController {
    enum Constants {
        static let widthRatio: CGFloat = 0.125
        static let nameTopOffset: CGFloat = 25
        static let heightRatio: CGFloat = 0.15
        static let priceTitleLabelTopOffset: CGFloat = 37.0
        static let priceInputMinWidth: CGFloat = 156.0

        static let documentationPath: String = "https://kassa.yandex.ru/msdk.html"
    }
}
