import UIKit.UIViewController

enum ContractAssembly {
    static func makeModule(inputData: ContractModuleInputData,
                           moduleOutput: ContractModuleOutput?) -> UIViewController {
        let viewController = ContractViewController()
        let presenter = ContractPresenter(inputData: inputData)

        let authorizationService
            = AuthorizationProcessingAssembly.makeService(testModeSettings: inputData.testModeSettings)
        let analyticsService = AnalyticsProcessingAssembly.makeAnalyticsService()
        let analyticsProvider = AnalyticsProvider(authorizationService: authorizationService)
        let interactor = ContractInteractor(analyticsService: analyticsService,
                                            analyticsProvider: analyticsProvider)

        let itemView
            = ContractViewFactory.makePaymentMethodView(paymentMethod: inputData.paymentMethod,
                                                        viewOutput: presenter,
                                                        shouldChangePaymentMethod: inputData.shouldChangePaymentMethod)

        viewController.output = presenter
        viewController.paymentMethodView = itemView
        viewController.templateViewController.output = presenter

        presenter.view = viewController
        presenter.interactor = interactor
        presenter.contractView = viewController.templateViewController
        presenter.moduleOutput = moduleOutput
        presenter.paymentMethodView = itemView

        return viewController
    }
}
