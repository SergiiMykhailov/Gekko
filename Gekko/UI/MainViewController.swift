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
                           OrdersViewDataSource {

    // MARK: Overriden functions

    override func viewDidLoad() {
        super.viewDidLoad()

        stackViewPlaceholder?.layer.cornerRadius = UIDefaults.CornerRadius
        collectionViewPlaceholder?.layer.cornerRadius = UIDefaults.CornerRadius
        chartViewPlaceholder?.layer.cornerRadius = UIDefaults.CornerRadius

        setupCurrenciesView()

        setupOrdersView()
        scheduleOrdersUpdating()

        scheduleDealsUpdating()

        setupChartView()
        scheduleCandlesUpdating()

        updateBalanceValueLabel()
        
        setupRefreshControl()
    }

    override func viewDidAppear(_ animated:Bool) {
        super.viewDidAppear(animated)

        let userDefaults = UserDefaults.standard

        publicKey = userDefaults.string(forKey:BTCTradeUAAccountSettingsViewController.PublicKeySettingsKey)
        privateKey = userDefaults.string(forKey:BTCTradeUAAccountSettingsViewController.PrivateKeySettingsKey)

        scheduleBalanceUpdating{}

        if isAuthorized && loginCompletionAction != nil {
            loginCompletionAction!()
            loginCompletionAction = nil
        }
    }

    // MARK: Internal methods and properties
    
    fileprivate var isAuthorized:Bool {
        return publicKey != nil && !publicKey!.isEmpty && privateKey != nil && !privateKey!.isEmpty
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

    fileprivate func scheduleBalanceUpdating(onCompletion: @escaping () -> Void) {
        if publicKey != nil && privateKey != nil {
            btcTradeUABalanceProvider.retriveBalanceAsync(withPublicKey:publicKey!,
                                                          privateKey:privateKey!,
                                                          onCompletion: { (balanceItems) in
                DispatchQueue.main.async { [weak self] () in
                    if (self != nil) {
                        self!.balance = balanceItems
                        self!.currenciesController.collectionView!.reloadData()
                        onCompletion()

                        if (self!.orderView?.superview == nil) {
                            self!.updateBalanceValueLabel()
                        }
                    }
                }
            })
        }

        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + MainViewController.BalancePollTimeout) {
            [weak self] () in
            if (self != nil) {
                self!.scheduleBalanceUpdating{}
            }
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

        ordersDataFacade = CoreDataFacade(completionBlock: { [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.scheduleOrdersStatusUpdating()
            }
        })
    }

    fileprivate func scheduleOrdersStatusUpdating() {
        handleOrdersStatusUpdating(onCompletion: {})

        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + MainViewController.OrdersPollTimeout) {
            [weak self] () in
            if (self != nil) {
                self!.scheduleOrdersStatusUpdating()
            }
        }
    }

    fileprivate func handleOrdersStatusUpdating(onCompletion:@escaping () -> Void) {
        let RequiredOperationsCount = 3
        var operationsCount = 0
        let completionHandler = {
            operationsCount += 1
        
            if operationsCount == RequiredOperationsCount {
                onCompletion()
            }
        }
        
        updateOrdersStatus(forCurrencyPair:.BtcUah, onCompletion:completionHandler)
        updateOrdersStatus(forCurrencyPair:.EthUah, onCompletion:completionHandler)
        updateOrdersStatus(forCurrencyPair:.LtcUah, onCompletion:completionHandler)
    }
    
    fileprivate func updateOrdersStatus(forCurrencyPair currencyPair:BTCTradeUACurrencyPair,
                                        onCompletion:@escaping () -> Void) {
        if let orders = ordersDataFacade?.orders(forCurrencyPair:currencyPair.rawValue as String) {
            let RequiredOrdersCount = orders.count
            var ordersCount = 0
            if RequiredOrdersCount == 0 {
                onCompletion()
            }
            let completionHandler = {
                ordersCount += 1
                print("OrdersCount = \(ordersCount) and RequiredOrdersCount = \(RequiredOrdersCount)")
                if ordersCount == RequiredOrdersCount {
                    onCompletion()
                }
            }
            
            for order in orders {
                btcTradeUAOrdersStatusProvider.retrieveStatusAsync(forOrderWithID:order.id!,
                                                                   publicKey:publicKey!,
                                                                   privateKey:privateKey!,
                                                                   onCompletion: { (status) in
                    DispatchQueue.main.async { [weak self] in
                        if (self == nil || status == nil) {
                            return
                        }

                        if (self!.currencyPairToUserOrdersStatusMap[currencyPair] == nil) {
                            self!.currencyPairToUserOrdersStatusMap[currencyPair] = [OrderStatusInfo]()
                        }

                        var ordersForCurrencyPair = self!.currencyPairToUserOrdersStatusMap[currencyPair]
                        if let existingOrderIndex = ordersForCurrencyPair?.index(where: { (currentOrder) -> Bool in
                            return currentOrder.id == order.id!
                        }) {
                            ordersForCurrencyPair![existingOrderIndex] = status!
                        }
                        else {
                            ordersForCurrencyPair!.append(status!)
                        }
                        
                        self!.currencyPairToUserOrdersStatusMap[currencyPair] = ordersForCurrencyPair
                        self!.userOrdersView.reloadData()
                    }
                completionHandler()
                })
            }
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

    fileprivate func scheduleOrdersUpdating() {
        handleOrdersUpdating(onCompletion: {})
        
        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + MainViewController.PricePollTimeout) {
            [weak self] () in
            if (self != nil) {
                self!.scheduleOrdersUpdating()
            }
        }
    }

    fileprivate func handleOrdersUpdating(onCompletion:@escaping () -> Void) {
        let RequiredOperationsCount = 6
        var operationsCount = 0
        let completionHandler:() -> Void = {
            operationsCount += 1
        
            if operationsCount == RequiredOperationsCount {
                onCompletion()
            }
        }
        
        handleOrdersUpdating(forPair:.BtcUah, onCompletion:completionHandler)
        handleOrdersUpdating(forPair:.EthUah, onCompletion:completionHandler)
        handleOrdersUpdating(forPair:.LtcUah, onCompletion:completionHandler)
    }
    
    fileprivate func handleOrdersUpdating(forPair pair:BTCTradeUACurrencyPair,
                                          onCompletion:@escaping () -> Void) {
        btcTradeUAOrderProvider.retrieveBuyOrdersAsync(forPair:pair,
                                                       withCompletionHandler: { (orders) in
                                                        DispatchQueue.main.async {
            [weak self] () in
                if (self != nil) {
                    self!.currencyPairToBuyOrdersMap[pair] = orders
                    onCompletion()
                    
                    if pair == self!.currentPair {
                        UIUtils.blink(aboveView:self!.ordersStackController.view)
                        self!.ordersStackController.reloadData()
                    }
                }
            }
        })

        btcTradeUAOrderProvider.retrieveSellOrdersAsync(forPair:pair,
                                                        withCompletionHandler: { (orders) in
                                                            DispatchQueue.main.async {
            [weak self] () in
                if (self != nil) {
                    self!.currencyPairToSellOrdersMap[pair] = orders
                    self!.ordersStackController.reloadData()
                    onCompletion()
                }
            }
        })
    }

    
    fileprivate func scheduleDealsUpdating() {
        handleDealsUpdating(onCompletion:{})

        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + MainViewController.PricePollTimeout) {
            [weak self] () in
            if (self != nil) {
                self!.scheduleDealsUpdating()
            }
        }
    }

    fileprivate func handleDealsUpdating(onCompletion:@escaping () -> Void) {
        let RequiredOperationsCount = 3
        var operationsCount = 0
        let completionHandler = {
            operationsCount += 1
            
            if operationsCount == RequiredOperationsCount {
                onCompletion()
            }
        }
        
        handleDealsUpdating(forPair:.BtcUah, onCompletion:completionHandler)
        handleDealsUpdating(forPair:.EthUah, onCompletion:completionHandler)
        handleDealsUpdating(forPair:.LtcUah, onCompletion:completionHandler)
    }
    
    fileprivate func handleDealsUpdating(forPair pair:BTCTradeUACurrencyPair,
                                         onCompletion:@escaping () -> Void) {
        btcTradeUAOrderProvider.retrieveDealsAsync(forPair:pair,
                                                   withCompletionHandler: { (deals,
                                                    minPrice,
                                                    maxPrice) in
            DispatchQueue.main.async { [weak self] () in
                if (self != nil) {
                    let currencyPairInfo = CurrencyPairInfo(minPrice:minPrice, maxPrice:maxPrice)
                    self!.currencyPairToCompletedOrdersMap[pair] = currencyPairInfo
                    self!.currenciesController.collectionView!.reloadData()
                    
                    onCompletion()
                }
            }
        })
    }
    
    fileprivate func balanceFor(currency:Currency) -> Double? {
        for balanceItem in balance {
            if balanceItem.currency == currency {
                return balanceItem.amount
            }
        }

        return nil
    }

    fileprivate func updateBalanceValueLabel(forCurrency currency:Currency = .UAH) {
        let balance = balanceFor(currency:currency)
        let formatString = currency == .UAH ?
            "%.02f (%@)" :
            "%.06f (%@)"

        let title = balance != nil ?
            String(format:formatString, balance!, currency.rawValue) :
            NSLocalizedString("Stock",
                              comment:"Main view controller title")
        self.title = title
    }

    fileprivate func setupChartView() {
        let separatorView = UIView()
        separatorView.backgroundColor = UIDefaults.SeparatorColor
        chartViewPlaceholder!.addSubview(separatorView)

        separatorView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview().offset(UIDefaults.LineHeight)
            make.height.equalTo(1)
        }

        let sellButton = UIButton(type:.system)
        sellButton.setTitle(NSLocalizedString("Sell", comment:"Sell button title"), for:.normal)
        sellButton.addTarget(self, action:#selector(sellButtonPressed(button:)), for:.touchUpInside)
        chartViewPlaceholder!.addSubview(sellButton)

        let buyButton = UIButton(type:.system)
        buyButton.setTitle(NSLocalizedString("Buy", comment:"Buy button title"), for:.normal)
        buyButton.addTarget(self, action:#selector(buyButtonPressed(button:)), for:.touchUpInside)
        chartViewPlaceholder!.addSubview(buyButton)

        let buySellButtonsSeparator = UIView()
        buySellButtonsSeparator.backgroundColor = UIDefaults.SeparatorColor
        chartViewPlaceholder!.addSubview(buySellButtonsSeparator)

        buySellButtonsSeparator.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(UIDefaults.Spacing)
            make.centerX.equalToSuperview()
            make.width.equalTo(1)
            make.bottom.equalTo(separatorView.snp.top).offset(-UIDefaults.Spacing)
        }

        sellButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(separatorView)
            make.right.equalTo(chartViewPlaceholder!.snp.centerX)
        }

        buyButton.snp.makeConstraints { (make) in
            make.left.equalTo(sellButton.snp.right)
            make.top.equalTo(sellButton)
            make.bottom.equalTo(sellButton)
            make.right.equalToSuperview()
        }

        chartViewPlaceholder!.addSubview(chartController.view)

        chartController.dataSource = self

        chartController.view.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalTo(separatorView.snp.bottom)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    fileprivate func scheduleCandlesUpdating() {
        handleCandlesUpdating(onCompletion: {})

        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + MainViewController.CandlesPollTimeout) {
            [weak self] () in
            if (self != nil) {
                self!.scheduleCandlesUpdating()
            }
        }
    }
    
    fileprivate func handleCandlesUpdating(onCompletion:@escaping () -> Void) {
        let RequiredOperationsCount = 3
        var operationsCount = 0
        let completionHandler = {
            operationsCount += 1
            
            if operationsCount == RequiredOperationsCount {
                onCompletion()
            }
        }
        
        handleCandlesUpdatingFor(pair:.BtcUah, onCompletion:completionHandler)
        handleCandlesUpdatingFor(pair:.EthUah, onCompletion:completionHandler)
        handleCandlesUpdatingFor(pair:.LtcUah, onCompletion:completionHandler)
    }

    fileprivate func handleCandlesUpdatingFor(pair:BTCTradeUACurrencyPair,
                                              onCompletion:@escaping () -> Void) {
        btcTradeUACandlesProvider.retrieveCandlesAsync(forPair:pair) { (candles) in
            DispatchQueue.main.async { [weak self] () in
                if self != nil {
                    self!.currencyPairToCandlesMap[pair] = candles
                    self!.chartController.reloadData()
                    onCompletion()
                }
            }
        }
    }

    fileprivate func loginIfNeeded(onCompletion:@escaping LoginCompletionAction) {
        if isAuthorized {
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
        let requiredOperationsCount = 5
        var completedOperationsCount = 0
        
        let handleOperationCompletion = {
            completedOperationsCount += 1
            print(completedOperationsCount)

            if (completedOperationsCount == requiredOperationsCount) {
                sender.endRefreshing()
            }
        }

        handleDealsUpdating(onCompletion:handleOperationCompletion)
        handleOrdersUpdating(onCompletion:handleOperationCompletion)
        handleOrdersStatusUpdating(onCompletion:handleOperationCompletion)
        scheduleBalanceUpdating(onCompletion:handleOperationCompletion)
        handleCandlesUpdating(onCompletion:handleOperationCompletion)
        
        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + MainViewController.PullDownRefreshingTimeout) {
            [weak self] () in
            if (self != nil) {
                sender.endRefreshing()
            }
        }
    }

    // MARK: CurrenciesCollectionViewControllerDataSource implementation

    internal func currenciesViewController(sender:CurrenciesCollectionViewController,
                                           balanceForCurrency currency:Currency) -> Double? {
        return balanceFor(currency:currency)
    }

    internal func currenciesViewController(sender:CurrenciesCollectionViewController,
                                           minPriceForCurrency currency:Currency) -> Double? {
        let currencyPair = MainViewController.CurrencyToCurrencyPairMap[currency]
        let currencyPairInfo = currencyPairToCompletedOrdersMap[currencyPair!]

        return currencyPairInfo != nil ? currencyPairInfo!.minPrice : nil
    }

    internal func currenciesViewController(sender:CurrenciesCollectionViewController,
                                  maxPriceForCurrency currency:Currency) -> Double? {
        let currencyPair = MainViewController.CurrencyToCurrencyPairMap[currency]
        let currencyPairInfo = currencyPairToCompletedOrdersMap[currencyPair!]

        return currencyPairInfo != nil ? currencyPairInfo!.maxPrice : nil
    }

    // MARK: CurrenciesCollectionViewControllerDelegate implementation

    internal func currenciesViewController(sender:CurrenciesCollectionViewController,
                                           didSelectCurrency currency:Currency) {
        currentPair = MainViewController.CurrencyToCurrencyPairMap[currency]!

        UIUtils.blink(aboveView:ordersStackController.view)
        UIUtils.blink(aboveView:chartController.view)

        ordersStackController.reloadData()
        chartController.reloadData()
        userOrdersView.reloadData()
    }

    fileprivate func presentOrderView(withMode mode:OrderMode,
                                      forCurrency currency:Currency) {
        if !isAuthorized {
            return
        }

        orderView?.removeFromSuperview()

        let availableAmount = balanceFor(currency:currency)
        orderView = CreateOrderView(withMode:mode,
                                    currency:currency,
                                    availableCryptocurrencyAmount:availableAmount != nil ? availableAmount! : 0)
        orderView?.backgroundColor = UIColor.white
        orderView?.delegate = self
        orderView?.layer.cornerRadius = UIDefaults.CornerRadius

        orderView?.alpha = 0
        mainScrollView!.addSubview(orderView!)

        orderView?.snp.makeConstraints({ (make) in
            make.top.equalTo(collectionViewPlaceholder!)
            make.left.equalToSuperview().priority(750)
            make.right.equalToSuperview().priority(750)
            make.height.equalTo(CreateOrderView.PreferredHeight)
        })

        self.view.layoutIfNeeded()

        self.stackViewPlaceholder!.snp.remakeConstraints({ (make) in
            make.top.equalTo(self.orderView!.snp.bottom).offset(UIDefaults.Spacing)
        })

        UIView.animate(withDuration:UIDefaults.DefaultAnimationDuration,
                       animations: {
            self.orderView?.alpha = 1
            self.collectionViewPlaceholder!.alpha = 0
            self.chartViewPlaceholder!.alpha = 0

            self.view.layoutIfNeeded()
        })
        { [weak self] (_) in
            _ = self?.orderView?.becomeFirstResponder()
        }

        currentOrderCurrency = currency

        if mode == .Sell {
            updateBalanceValueLabel(forCurrency:currency)
        }
    }

    fileprivate func dismissOrderView() {
        self.stackViewPlaceholder!.snp.remakeConstraints({ (make) in
            make.top.equalTo(self.chartViewPlaceholder!.snp.bottom).offset(UIDefaults.Spacing)
        })

        UIView.animate(withDuration:UIDefaults.DefaultAnimationDuration,
                       animations: {
            self.view.layoutIfNeeded()

            self.orderView?.alpha = 0
            self.collectionViewPlaceholder!.alpha = 1
            self.chartViewPlaceholder!.alpha = 1
        }) { (_) in
            self.orderView?.removeFromSuperview()
            self.orderView = nil

            self.updateBalanceValueLabel()
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
        let timeout = sender.isFirstResponder ? UIDefaults.DefaultAnimationDuration : 0
        _ = sender.resignFirstResponder()
        let orderCurrency = currentOrderCurrency
        let pair = currentPair

        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + timeout) {
            self.animateOrderSubmitting(withOrderView:sender,
                                        forMode:mode,
                                        completion: {
                if mode == .Buy {
                    self.btcTradeUAOrderProvider.performBuyOrderAsync(forCurrency:orderCurrency!,
                                                                      amount:amount,
                                                                      price:price,
                                                                      publicKey:self.publicKey!,
                                                                      privateKey:self.privateKey!,
                                                                      onCompletion:
                    { [weak self] (orderId) in
                        self?.ordersDataFacade!.makeOrder(withInitializationBlock: { (order) in
                            order.id = orderId
                            order.isBuy = true
                            order.currency = pair.rawValue as String
                            order.date = Date()
                            order.initialAmount = amount
                            order.price = price
                        })
                    })
                }
                else {
                    self.btcTradeUAOrderProvider.performSellOrderAsync(forCurrency:self.currentOrderCurrency!,
                                                                       amount:amount,
                                                                       price:price,
                                                                       publicKey:self.publicKey!,
                                                                       privateKey:self.privateKey!,
                                                                       onCompletion:
                    { [weak self] (orderId) in
                        self?.ordersDataFacade!.makeOrder(withInitializationBlock: { (order) in
                            order.id = orderId
                            order.isBuy = false
                            order.currency = pair.rawValue as String
                            order.date = Date()
                            order.initialAmount = amount
                            order.price = price
                        })
                    })
                }
                                            
                self.chartController.reloadData()
            })
        }
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
        let candles = currencyPairToCandlesMap[currentPair]
        return candles != nil ? candles! : [CandleInfo]()
    }

    // MARK: OrdersStackViewControllerDataSource implementation

    func sellOrdersForOrdersViewController(sender:OrdersStackViewController) -> [OrderInfo] {
        return orders(fromDictionary:currencyPairToSellOrdersMap)
    }

    func buyOrdersForOrdersViewController(sender:OrdersStackViewController) -> [OrderInfo] {
        return orders(fromDictionary:currencyPairToBuyOrdersMap)
    }

    fileprivate func orders(fromDictionary dictionary:[BTCTradeUACurrencyPair : [OrderInfo]]) -> [OrderInfo] {
        if let orders = dictionary[currentPair] {
            return orders
        }

        return [OrderInfo]()
    }

    // MARK: OrdersViewDataSource implementation

    func ordersFor(ordersView sender:OrdersView) -> [OrderStatusInfo] {
        let result = currencyPairToUserOrdersStatusMap[currentPair]

        if result != nil {
            return result!
        }

        return [OrderStatusInfo]()
    }

    // MARK: OrdersViewDelegate implementation
    
    func ordersView(sender:OrdersView, didRequestCancel order:OrderStatusInfo) {
        var currentPairOrders = currencyPairToUserOrdersStatusMap[currentPair]
        currentPairOrders = currentPairOrders?.filter({ (currentOrderStatus) -> Bool in
            currentOrderStatus.id != order.id
        })

        currencyPairToUserOrdersStatusMap[currentPair] = currentPairOrders
        
        btcTradeUAOrderProvider.cancelOrderAsync(withID:order.id,
                                                 publicKey:publicKey!,
                                                 privateKey:privateKey!) {
                                                    
        }
    }
    
    // MARK: Events handling

    @objc fileprivate func buyButtonPressed(button:UIButton) -> Void {
        loginIfNeeded { [weak self] () in
            if self != nil {
                self!.presentOrderView(withMode:.Buy,
                                       forCurrency:self!.currenciesController.selectedCurrency!)
            }
        }
    }

    @objc fileprivate func sellButtonPressed(button:UIButton) -> Void {
        loginIfNeeded { [weak self] () in
            if self != nil {
                self!.presentOrderView(withMode:.Sell,
                                       forCurrency:self!.currenciesController.selectedCurrency!)
            }
        }
    }

    // MARK: Outlets

    @IBOutlet weak var mainScrollView:UIScrollView?
    @IBOutlet weak var collectionViewPlaceholder:UIView?
    @IBOutlet weak var chartViewPlaceholder:UIView?
    @IBOutlet weak var stackViewPlaceholder:UIView?

    // MARK: Internal fields

    fileprivate struct CurrencyPairInfo {
        var minPrice:Double
        var maxPrice:Double
    }

    fileprivate var currencyPairToCompletedOrdersMap = [BTCTradeUACurrencyPair : CurrencyPairInfo]()
    fileprivate var currencyPairToBuyOrdersMap = [BTCTradeUACurrencyPair : [OrderInfo]]()
    fileprivate var currencyPairToSellOrdersMap = [BTCTradeUACurrencyPair : [OrderInfo]]()
    fileprivate var currencyPairToCandlesMap = [BTCTradeUACurrencyPair : [CandleInfo]]()

    fileprivate let btcTradeUABalanceProvider = BTCTradeUABalanceProvider()
    fileprivate let btcTradeUACandlesProvider = BTCTradeUACandlesProvider()
    fileprivate let btcTradeUAOrderProvider = BTCTradeUAOrderProvider()
    fileprivate let btcTradeUAOrdersStatusProvider = BTCTradeUAOrdersStatusProvider()
    fileprivate var currentOrderCurrency:Currency?

    fileprivate var currentPair = BTCTradeUACurrencyPair.BtcUah
    fileprivate var balance = [BalanceItem]()

    fileprivate let currenciesController = CurrenciesCollectionViewController()
    fileprivate let chartController = ChartViewController()

    fileprivate let ordersStackController = OrdersStackViewController()
    fileprivate let userOrdersView = OrdersView()
    fileprivate var orderView:CreateOrderView?
    fileprivate var ordersDataFacade:CoreDataFacade?
    fileprivate var currencyPairToUserOrdersStatusMap = [BTCTradeUACurrencyPair : [OrderStatusInfo]]()

    fileprivate var publicKey:String?
    fileprivate var privateKey:String?

typealias LoginCompletionAction = () -> Void

    fileprivate var loginCompletionAction:LoginCompletionAction?

    fileprivate static let BalancePollTimeout:TimeInterval = 20
    fileprivate static let PricePollTimeout:TimeInterval = 10
    fileprivate static let CandlesPollTimeout:TimeInterval = 30
    fileprivate static let OrdersPollTimeout:TimeInterval = 10
    fileprivate static let PullDownRefreshingTimeout:TimeInterval = 3

    fileprivate static let CurrencyToCurrencyPairMap = [Currency.BTC : BTCTradeUACurrencyPair.BtcUah,
                                                        Currency.ETH : BTCTradeUACurrencyPair.EthUah,
                                                        Currency.LTC : BTCTradeUACurrencyPair.LtcUah]

    fileprivate static let ShowAccountSettingsSegueName = "Show Account Settings"

    fileprivate static let MainTabIndex = 0
    fileprivate static let SettingsTabIndex = 1
}

