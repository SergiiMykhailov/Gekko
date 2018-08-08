//  Created by Sergii Mykhailov on 19/11/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import UIKit
import SnapKit

class MainViewController : UIViewController,
                           CurrenciesCollectionViewControllerDataSource,
                           CurrenciesCollectionViewControllerDelegate,
                           ChartViewControllerDataSource,
                           CreateOrderViewDelegate,
                           OrdersStackViewControllerDataSource,
                           OrdersViewDelegate,
                           OrdersViewDataSource,
                           TradingPlatformAccessibilityControllerDelegate,
                           AssetsViewControllerDataSource,
                           TradingPlatformManagerDelegate {

    // MARK: Overriden functions

    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath:UIUtils.PrivateKeySettingsKey)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTradingPlatform()

        stackViewPlaceholder?.layer.cornerRadius = UIDefaults.CornerRadius
        collectionViewPlaceholder?.layer.cornerRadius = UIDefaults.CornerRadius
        buttonsPlaceholder?.layer.cornerRadius = UIDefaults.CornerRadius
        chartViewPlaceholder?.layer.cornerRadius = UIDefaults.CornerRadius
        
        setupCurrenciesView()

        setupOrdersView()

        setupChartView()
        setupButtons()
        
        setupServerErrorView()
        
        setupRefreshControl()
        
        serverAccessibility.delegate = self
        serverAccessibility.startMonitoringAccessibility()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image:#imageLiteral(resourceName: "user"),
                                                            style:.plain,
                                                            target:self,
                                                            action:#selector(accountSettingsButtonPressed))
        navigationItem.rightBarButtonItem?.tintColor = UIColor.black

        if (tradingPlatform.assetsHandler != nil) {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image:#imageLiteral(resourceName: "currencies"),
                                                               style:.plain,
                                                               target:self,
                                                               action:#selector(balanceSettingsButtonPressed))
            navigationItem.leftBarButtonItem?.tintColor = UIColor.black
            navigationItem.leftBarButtonItem?.isEnabled = tradingPlatform.isAuthorized
        }

        TradingPlatformManager.shared.delegate = self
    }
    
    override func viewDidAppear(_ animated:Bool) {
        super.viewDidAppear(animated)
        
        updateBalanceValueLabel()

        if tradingPlatform.isAuthorized && loginCompletionAction != nil {
            loginCompletionAction!()
            loginCompletionAction = nil
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let assetsViewController = segue.destination as? AssetsViewController {
            assetsViewController.dataSource = self
        }
    }

    // MARK: Internal methods and properties

    fileprivate var supportedAssets:[Currency] {
        get {
            let supportedPairs = tradingPlatform.supportedCurrencyPairs
            var result = [Currency]()

            for currencyPair in supportedPairs {
                result.append(currencyPair.secondaryCurrency)
            }

            return result
        }
    }

    fileprivate var tradingPlatform:TradingPlatform {
        get {
            return tradingPlatformController!.tradingPlatform
        }
    }

    fileprivate func setupTradingPlatform() {
        let tradingPlatform = TradingPlatformManager.shared.tradingPlatform
        tradingPlatformController = TradingPlatformController(tradingPlatform:tradingPlatform)
        tradingPlatformController?.activeCurrencyPair = makePairForCurrency(forCurrency:.BTC)

        subscribeForTradingPlatformDataUpdates()

        tradingPlatformController?.start()
        tradingPlatformController?.refreshAll()

        if let assetsProvider = tradingPlatform.assetsHandler {
            tradingPlatformAssetsManager = TradingPlatformAssetsManager(withAssetProvider:assetsProvider,
                                                                        assets:supportedAssets)
        }
    }

    fileprivate func subscribeForTradingPlatformDataUpdates() {
        let notifications = tradingPlatformController?.notifications

        notifications?.onUserBalanceUpdated = {
            [weak self] (currency) in
            self?.tradingPlatformController?.readonlyModel.allBalanceItems(handlingBlock: { [weak self] (balanceItems) in
                if self != nil && !balanceItems.isEmpty {
                    self!.currenciesController.collectionView!.reloadData()

                    if (self!.orderView?.superview == nil) {
                        self!.updateBalanceValueLabel()
                    }
                }
            })
        }

        let executeIfCurrencyPairMatches = { [weak self] (currencyPair:CurrencyPair,
                                                          block:() -> Void) in
            if self != nil && self!.tradingPlatformController!.activeCurrencyPair! == currencyPair {
                block()
            }
        }

        let handleOrdersUpdating = { (currencyPair:CurrencyPair) in
            executeIfCurrencyPairMatches(currencyPair,
                                         { [weak self] in
                UIUtils.blink(aboveView:self!.ordersStackController.view)
                self?.ordersStackController.reloadData()
            })
        }

        notifications?.onBuyOrdersUpdated = handleOrdersUpdating
        notifications?.onSellOrdersUpdated = handleOrdersUpdating

        notifications?.onDealsUpdated = {
            (currencyPair) in
            executeIfCurrencyPairMatches(currencyPair,
                                         { [weak self] in
                UIUtils.blink(aboveView:self!.currenciesController.collectionView!)
                self?.currenciesController.collectionView!.reloadData()
            })
        }

        notifications?.onCandlesUpdated = {
            (currencyPair) in
            executeIfCurrencyPairMatches(currencyPair,
                                         { [weak self] in
                self?.chartController.reloadData()
            })
        }

        notifications?.onUserOrdersStatusUpdated = {
            (currencyPair) in
            executeIfCurrencyPairMatches(currencyPair,
                                         { [weak self] in
                                            UIUtils.blink(aboveView:self!.userOrdersView)
                                            self?.userOrdersView.reloadData()
            })
        }
    }

    fileprivate func handleOrderSubmission(withCryptocurrencyAmount amount:Double,
                                           price:Double,
                                           mode:OrderMode) {
        let timeout = orderView!.isFirstResponder ? UIDefaults.DefaultAnimationDuration : 0
        _ = orderView!.resignFirstResponder()
        let orderCurrency = currentOrderCurrency
        
        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + timeout) {
            [weak self] in
            self!.animateOrderSubmitting(withOrderView:self!.orderView!,
                                         forMode:mode,
                                         completion: {
                [weak self] in
                let orderPostingMethod = mode == .Buy
                                                 ? self!.tradingPlatformController!.performBuyOrderAsync
                                                 : self!.tradingPlatformController!.performSellOrderAsync

                let currencyPair = CurrencyPair(primaryCurrency:self!.tradingPlatform.mainCurrency,
                                                secondaryCurrency:orderCurrency!)
                orderPostingMethod(currencyPair,
                                   amount,
                                   price,
                { [weak self] (orderId) in
                    DispatchQueue.main.async {
                        if orderId == nil {
                            return
                        }

                        self!.userOrdersView.reloadData()
                        self!.chartController.reloadData()
                    }
                })
            })
        }
    }

    fileprivate func setupCurrenciesView() {
        collectionViewPlaceholder!.addSubview(currenciesController.collectionView!)

        currenciesController.dataSource = self
        currenciesController.delegate = self
        currenciesController.collectionView?.selectItem(at:IndexPath(row:0, section:0),
                                                        animated:false,
                                                        scrollPosition:.left)

        currenciesController.collectionView!.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    fileprivate func setupOrdersView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(ordersPlaceholderTapped))
        tapGestureRecognizer.numberOfTapsRequired = 1

        userOrdersView.dataSource = self
        userOrdersView.delegate = self

        stackViewPlaceholder?.addGestureRecognizer(tapGestureRecognizer)

        stackViewPlaceholder!.addSubview(userOrdersView)
        userOrdersView.backgroundColor = UIColor.white

        stackViewPlaceholder!.addSubview(ordersStackController.view)
        ordersStackController.dataSource = self
        ordersStackController.view!.backgroundColor = UIColor.white

        userOrdersView.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })

        ordersStackController.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    @objc func ordersPlaceholderTapped(gestureRecognizer:UITapGestureRecognizer) {
        let positionInView = gestureRecognizer.location(in:stackViewPlaceholder!)
        let containerViewWidth = stackViewPlaceholder!.frame.width
        let flipDirection = positionInView.x < containerViewWidth / 2 ?
            UIViewAnimationOptions.transitionFlipFromRight :
            UIViewAnimationOptions.transitionFlipFromLeft

        let sourceView = stackViewPlaceholder!.subviews.last
        let targetView = stackViewPlaceholder!.subviews.first

        let options:UIViewAnimationOptions = [flipDirection, UIViewAnimationOptions.showHideTransitionViews]

        UIView.transition(from:sourceView!,
                          to:targetView!,
                          duration:UIDefaults.DefaultAnimationDuration * 3,
                          options:options) { _ in
            self.stackViewPlaceholder!.sendSubview(toBack:sourceView!)
        }
    }

    fileprivate func updateBalanceValueLabel(forCurrency currency:Currency = .UAH) {
        tradingPlatformController?.readonlyModel.allBalanceItems(handlingBlock: { [weak self] (balanceItems) in
            let balanceItem = balanceItems.first(where: { return $0.currency == currency })
            let formatString = currency == .UAH ?
                "%.02f (%@)" :
                "%.06f (%@)"

            let title = balanceItem != nil ?
                String(format:formatString, balanceItem!.amount, currency.rawValue) :
                NSLocalizedString("Stock",
                                  comment:"Main view controller title")
            self?.title = title
        })
    }

    fileprivate func setupButtons() {
        if sellButton == nil || buyButton == nil {
            return
        }
        
        sellButton!.setTitle(NSLocalizedString("Sell", comment:"Sell button title"), for:.normal)
        sellButton!.backgroundColor = UIDefaults.RedColor
        
        buyButton!.setTitle(NSLocalizedString("Buy", comment:"Buy button title"), for:.normal)
        buyButton!.backgroundColor = UIDefaults.GreenColor
        
        sellButton!.snp.remakeConstraints({ (make) in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            
            if orderView == nil {
                make.right.equalTo(sellButton!.superview!.snp.centerX)
            }
            else {
                if orderView!.mode == .Buy {
                    make.right.equalTo(sellButton!.superview!.snp.left)
                }
                else {
                    make.right.equalToSuperview()
                }
            }
        })
        
        buyButton!.snp.remakeConstraints({ (make) in
            make.left.equalTo(sellButton!.snp.right)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.right.equalToSuperview()
        })
    }
    
    fileprivate func setupChartView() {
        chartViewPlaceholder!.addSubview(chartController.view)

        chartController.dataSource = self

        chartController.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    fileprivate func loginIfNeeded(onCompletion:@escaping LoginCompletionAction) {
        if tradingPlatformController!.tradingPlatform.isAuthorized {
            onCompletion()
            return
        }

        loginCompletionAction = onCompletion

        performSegue(withIdentifier:MainViewController.ShowAccountSettingsSegueName,
                     sender:self)
    }
    
    fileprivate func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshMainView(sender:)), for: .valueChanged)
        mainScrollView?.refreshControl = refreshControl
    }
    
    @objc fileprivate func refreshMainView(sender:UIRefreshControl) {
        tradingPlatformController?.refreshAll()
        
        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + MainViewController.PullDownRefreshingTimeout) {
            [weak self] () in
            if self != nil && sender.isRefreshing {
                sender.endRefreshing()
            }
        }
    }
    
    fileprivate func setupServerErrorView () {
        serverErrorView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        serverErrorView.layer.cornerRadius = UIDefaults.CornerRadius
        serverErrorView.isUserInteractionEnabled = false
        serverErrorView.alpha = 0
        
        let imageView = UIImageView(image: #imageLiteral(resourceName: "serverError"))
        serverErrorView.addSubview(imageView)
        
        imageView.snp.makeConstraints { (make) in
            make.width.equalTo(100)
            make.height.equalTo(100)
            make.center.equalToSuperview()
        }
    }

    // MARK: TradingPlatformAccessibilityControllerDelegate implementation

    internal func tradingPlatformAccessibilityControllerDidDetectConnectionFailure(_ sender:TradingPlatformAccessibilityController) {
        self.view.addSubview(serverErrorView)
        
        serverErrorView.snp.makeConstraints { (make) in
            make.width.equalTo(150)
            make.height.equalTo(150)
            make.center.equalToSuperview()
        }
        
        UIView.animate(withDuration: UIDefaults.DefaultAnimationDuration) {
            self.serverErrorView.alpha = 0.1
        }
    }

    internal func tradingPlatformAccessibilityControllerDidDetectConnectionRestore(_ sender:TradingPlatformAccessibilityController) {
        UIView.animate(withDuration: UIDefaults.DefaultAnimationDuration,
                       animations: {
                        self.serverErrorView.alpha = 0
                    }, completion: ({ _ in
                        self.serverErrorView.removeFromSuperview()
                    }))
    }

    // MARK: CurrenciesCollectionViewControllerDataSource implementation

    internal func supportedCurrencies(forCurrenciesCollectionViewController sender:CurrenciesCollectionViewController) -> [Currency] {
        return supportedAssets
    }

    internal func currenciesViewController(sender:CurrenciesCollectionViewController,
                                           balanceForCurrency currency:Currency) -> Double? {
        var result:Double? = nil

        tradingPlatformController?.readonlyModel.allBalanceItems(handlingBlock: { (balanceItems) in
            result = balanceItems.first(where: { return $0.currency == currency } )?.amount
        })

        return result
    }
    
    fileprivate func makePairForCurrency(forCurrency currency:Currency) -> CurrencyPair {
        let currencyPair = CurrencyPair(primaryCurrency:tradingPlatformController!.tradingPlatform.mainCurrency,
                                        secondaryCurrency:currency)
                                        
        return currencyPair
    }

    internal func currenciesViewController(sender:CurrenciesCollectionViewController,
                                           minPriceForCurrency currency:Currency) -> Double? {
        let currencyPair = makePairForCurrency(forCurrency:currency)
        var result:Double?

        tradingPlatformController?.readonlyModel.allDealsRange(forCurrencyPair:currencyPair,
                                                               handlingBlock: { (candle) in
            result = candle?.low
        })

        return result
    }

    internal func currenciesViewController(sender:CurrenciesCollectionViewController,
                                           maxPriceForCurrency currency:Currency) -> Double? {
        let currencyPair = makePairForCurrency(forCurrency:currency)
        var result:Double?

        tradingPlatformController?.readonlyModel.allDealsRange(forCurrencyPair:currencyPair,
                                                               handlingBlock: { (candle) in
            result = candle?.high
        })

        return result
    }

    internal func currenciesViewController(sender:CurrenciesCollectionViewController,
                                           dailyUpdateInPercentsForCurrency currency:Currency) -> Double? {
        let currencyPair = makePairForCurrency(forCurrency:currency)
        var result:Double?

        tradingPlatformController?.readonlyModel.allDealsRange(forCurrencyPair:currencyPair,
                                                               handlingBlock: { (candle) in
            if candle != nil {
                let percentage = 100 * (candle!.close - candle!.open) / candle!.open
                result = percentage
            }
        })

        return result
    }

    // MARK: CurrenciesCollectionViewControllerDelegate implementation

    internal func currenciesViewController(sender:CurrenciesCollectionViewController,
                                           didSelectCurrency currency:Currency) {
        tradingPlatformController?.activeCurrencyPair = makePairForCurrency(forCurrency:currency)
        tradingPlatformController?.refreshAll()

        UIUtils.blink(aboveView:ordersStackController.view)
        UIUtils.blink(aboveView:chartController.view)

        ordersStackController.reloadData()
        chartController.reloadData()
        userOrdersView.reloadData()
    }

    fileprivate func presentOrderView(withMode mode:OrderMode,
                                      forCurrency currency:Currency) {
        if !tradingPlatformController!.tradingPlatform.isAuthorized {
            return
        }

        orderView?.removeFromSuperview()

        orderView = CreateOrderView(withMode:mode,
                                    currency:currency)
        orderView?.backgroundColor = UIColor.white
        orderView?.delegate = self
        orderView?.layer.cornerRadius = UIDefaults.CornerRadius

        orderView?.alpha = 0
        chartViewPlaceholder?.addSubview(orderView!)

        orderView?.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })

        self.view.layoutIfNeeded()
        
        UIView.animate(withDuration:UIDefaults.DefaultAnimationDuration,
                       animations: {
                        [weak self] in
            self?.collectionViewPlaceholder?.alpha = 0
        }) { [weak self] (_) in
            let verticalOffset = self!.chartViewPlaceholder!.frame.origin.y - UIDefaults.Spacing
            let contentOffset = CGPoint(x:0, y:verticalOffset)
            self?.mainScrollView?.setContentOffset(contentOffset,
                                                   animated:true)
            
            DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + UIDefaults.DefaultAnimationDuration,
                                           execute: {
                    UIView.animate(withDuration:UIDefaults.DefaultAnimationDuration,
                                   animations: { [weak self] in
                        self?.orderView?.alpha = 1
                                                            
                        self?.setupButtons()
                        self?.view.layoutIfNeeded()
                    })
                    { [weak self] (_) in
                        _ = self?.orderView?.becomeFirstResponder()
                                                
                        self?.mainScrollView?.contentInset = UIEdgeInsets(top:-verticalOffset,
                                                                          left:0,
                                                                          bottom:0,
                                                                          right:0)
                    }
            })
        }
        
        currentOrderCurrency = currency

        if mode == .Sell {
            updateBalanceValueLabel(forCurrency:currency)
        }
    }

    fileprivate func dismissOrderView() {
        UIView.animate(withDuration:UIDefaults.DefaultAnimationDuration,
                       animations: { [weak self] in
            self?.orderView?.alpha = 0
                        
            self?.mainScrollView?.setContentOffset(CGPoint(x:0, y:0), animated:true)
        }) { [weak self] (_) in
            self?.orderView?.removeFromSuperview()
            self?.orderView = nil

            UIView.animate(withDuration:UIDefaults.DefaultAnimationDuration,
                           animations: { [weak self] in
                self?.collectionViewPlaceholder?.alpha = 1
                self?.setupButtons()
                            
                self?.view.layoutIfNeeded()
            },
                           completion: { [weak self] (_) in
                self?.mainScrollView?.contentInset = UIEdgeInsets(top:0, left:0, bottom:0, right:0)
                self?.updateBalanceValueLabel()
            })
        }
    }

    // MARK: CreateOrderViewDelegate implementation

    func createOrderViewDidCancelRequest(sender:CreateOrderView) {
        dismissOrderView()
        
        self.chartController.reloadData()
    }

    func createOrderView(sender:CreateOrderView,
                         didSubmitRequestWithAmount amount:Double,
                         price:Double,
                         forMode mode:OrderMode) {
        handleOrderSubmission(withCryptocurrencyAmount:amount, price:price, mode:mode)
    }

    fileprivate func animateOrderSubmitting(withOrderView orderView:CreateOrderView,
                                            forMode mode:OrderMode,
                                            completion:@escaping () -> Void) {
        orderView.snp.remakeConstraints { (make) in
            make.width.equalTo(10).priority(1000)
            make.height.equalTo(10).priority(1000)
            make.centerY.equalTo(stackViewPlaceholder!)

            var horizontalOffset = self.stackViewPlaceholder!.frame.width / 4
            if mode == .Buy {
                horizontalOffset *= -1
            }

            make.centerX.equalTo(stackViewPlaceholder!).offset(horizontalOffset)
        }

        UIView.animate(withDuration:UIDefaults.DefaultAnimationDuration,
                       animations: {
            self.view.layoutIfNeeded()
            orderView.alpha = 0
        }) { (_) in
            self.dismissOrderView()
            completion()
        }
    }

    // MARK: ChartViewControllerDataSource implementation

    func dataForChartViewController(sender:ChartViewController) -> [CandleInfo] {
        var result = [CandleInfo]()

        if tradingPlatformController != nil {
            let activeCurrencyPair = tradingPlatformController!.activeCurrencyPair!
            tradingPlatformController!.readonlyModel.candles(forCurrencyPair:activeCurrencyPair,
                                                             handlingBlock: { [weak self] (candles) in
                result = candles != nil ? candles! : result

                if !result.isEmpty {
                    self?.tradingPlatformController!.readonlyModel.allDealsRange(forCurrencyPair:activeCurrencyPair,
                                                                                 handlingBlock: { (candle) in
                        if candle != nil {
                            result[result.count - 1].close = candle!.close
                        }
                    })
                }
            })
        }

        return result
    }

    // MARK: OrdersStackViewControllerDataSource implementation

    func sellOrdersForOrdersViewController(sender:OrdersStackViewController) -> [OrderInfo] {
        var result = [OrderInfo]()

        if tradingPlatformController != nil {
            let activeCurrencyPair = tradingPlatformController!.activeCurrencyPair!
            tradingPlatformController?.readonlyModel.allSellOrders(forCurrencyPair:activeCurrencyPair,
                                                                   handlingBlock: { (orders) in
                result = orders != nil ? orders! : result
            })
        }

        return result
    }

    func buyOrdersForOrdersViewController(sender:OrdersStackViewController) -> [OrderInfo] {
        var result = [OrderInfo]()

        if tradingPlatformController != nil {
            let activeCurrencyPair = tradingPlatformController!.activeCurrencyPair!
            tradingPlatformController?.readonlyModel.allBuyOrders(forCurrencyPair:activeCurrencyPair,
                                                                   handlingBlock: { (orders) in
                result = orders != nil ? orders! : result
            })
        }

        return result
    }

    fileprivate func orders(fromDictionary dictionary:[CurrencyPair : [OrderInfo]]) -> [OrderInfo] {
        if let orders = dictionary[tradingPlatformController!.activeCurrencyPair!] {
            return orders
        }

        return [OrderInfo]()
    }

    // MARK: OrdersViewDataSource implementation

    func ordersAndCompletedDealsFor(ordersView sender:OrdersView) -> [OrderStatusInfo] {
        var result = [OrderStatusInfo]()

        if tradingPlatformController != nil {
            let activeCurrencyPair = tradingPlatformController!.activeCurrencyPair!

            tradingPlatformController!.readonlyModel.userOrdersStatus(forCurrencyPair:activeCurrencyPair) { (userOrders) in
                if userOrders != nil {
                    result.append(contentsOf:userOrders!)
                }
            }

            tradingPlatformController!.readonlyModel.userDeals(forCurrencyPair:activeCurrencyPair) { (userCompletedDeals) in
                if userCompletedDeals != nil {
                    result.append(contentsOf:userCompletedDeals!)
                }
            }
        }

        return result
    }

    // MARK: OrdersViewDelegate implementation
    
    func ordersView(sender:OrdersView, didRequestCancel order:OrderStatusInfo) {
        tradingPlatformController!.cancelOrderAsync(withID:order.id) { }
    }

    // MARK: CryptoAssetsViewControllerDataSource implementation

    func supportedAssets(forCryptoAssetsViewController sender:AssetsViewController) -> [Currency] {
        var assets = [tradingPlatform.mainCurrency]
        assets.append(contentsOf:supportedAssets)

        return assets
    }

    func keys(forAsset asset:Currency,
              forCryptoAssetsViewController sender:AssetsViewController) -> [String] {
        return tradingPlatformAssetsManager != nil ? tradingPlatformAssetsManager!.keys(forAsset:asset) : [String]()
    }

    // MARK: TradingPlatformManagerDelegate implementation

    func tradingPlatformManager(sender: TradingPlatformManager, didCreateTradingPlatform tradingPlatform: TradingPlatform) {
        setupTradingPlatform()

        navigationItem.leftBarButtonItem?.isEnabled = tradingPlatform.isAuthorized
    }
    
    // MARK: Events handling

    @IBAction fileprivate func buyButtonPressed(button:UIButton) -> Void {
        handleButton(forOrderMode:.Buy)
    }

    @IBAction fileprivate func sellButtonPressed(button:UIButton) -> Void {
        handleButton(forOrderMode:.Sell)
    }
    
    fileprivate func handleButton(forOrderMode mode:OrderMode) {
        loginIfNeeded { [weak self] () in
            if self != nil {
                if self!.orderView == nil {
                    self!.presentOrderView(withMode:mode,
                                           forCurrency:self!.currenciesController.selectedCurrency!)
                }
                else if self!.orderView!.price != nil &&
                        self!.orderView!.amount != nil {
                    self!.handleOrderSubmission(withCryptocurrencyAmount:self!.orderView!.amount!,
                                                price:self!.orderView!.price!,
                                                mode:mode)
                }
            }
        }
    }
    
    @objc fileprivate func accountSettingsButtonPressed(button:UIButton) {
        if !tradingPlatform.isAuthorized {
            performSegue(withIdentifier:MainViewController.ShowAccountSettingsSegueName, sender:self)
        }
        else {
            UIUtils.authenticate { (succeeded, _) in
                if succeeded {
                    DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + 2 * UIDefaults.DefaultAnimationDuration) {
                        [weak self] in
                        self?.performSegue(withIdentifier:MainViewController.ShowAccountDetailsSegueName, sender:self!)
                    }
                }
            }
        }
    }

    @objc fileprivate func balanceSettingsButtonPressed(button:UIButton) {
        performSegue(withIdentifier:MainViewController.ShowAssetsSegueName, sender:self)
    }

    // MARK: Outlets

    @IBOutlet weak var mainScrollView:UIScrollView?
    @IBOutlet weak var collectionViewPlaceholder:UIView?
    @IBOutlet weak var chartViewPlaceholder:UIView?
    @IBOutlet weak var buttonsPlaceholder:UIView?
    @IBOutlet weak var stackViewPlaceholder:UIView?
    
    @IBOutlet weak var buyButton:UIButton?
    @IBOutlet weak var sellButton:UIButton?

    // MARK: Internal fields

    fileprivate struct CurrencyPairInfo {
        var minPrice:Double
        var maxPrice:Double
    }

    fileprivate var tradingPlatformController:TradingPlatformController?
    fileprivate var tradingPlatformAssetsManager:TradingPlatformAssetsManager?

    fileprivate var currentOrderCurrency:Currency?

    fileprivate let currenciesController = CurrenciesCollectionViewController()
    fileprivate let chartController = ChartViewController()
    fileprivate let ordersStackController = OrdersStackViewController()
    fileprivate let userOrdersView = OrdersView()
    fileprivate var orderView:CreateOrderView?
    fileprivate let serverErrorView = UIView()
    
    fileprivate let serverAccessibility = TradingPlatformAccessibilityController()

typealias LoginCompletionAction = () -> Void

    fileprivate var loginCompletionAction:LoginCompletionAction?

    fileprivate static let PullDownRefreshingTimeout:TimeInterval = 5

    fileprivate static let ShowAccountSettingsSegueName = "Show Account Settings"
    fileprivate static let ShowAccountDetailsSegueName = "Show Account Details"
    fileprivate static let ShowAssetsSegueName = "Show Assets"

    fileprivate static let MainTabIndex = 0
    fileprivate static let SettingsTabIndex = 1
}

