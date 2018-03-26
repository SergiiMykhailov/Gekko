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
        buttonsPlaceholder?.layer.cornerRadius = UIDefaults.CornerRadius
        chartViewPlaceholder?.layer.cornerRadius = UIDefaults.CornerRadius
        
        setupCurrenciesView()

        setupOrdersView()
        scheduleOrdersUpdating()
        
        scheduleDealsUpdating()

        setupChartView()
        setupButtons()
        scheduleCandlesUpdating()
        
        setupRefreshControl()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "settings"), style: .plain, target: self, action:#selector(settingsButtonPressed))
        
        coreDataFacade = CoreDataFacade(completionBlock: { [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.scheduleOrdersStatusUpdating()
                self?.loadStoredBalance()
            }
        })
    }

    override func viewDidAppear(_ animated:Bool) {
        super.viewDidAppear(animated)

        let userDefaults = UserDefaults.standard

        publicKey = userDefaults.string(forKey:UIUtils.PublicKeySettingsKey)
        privateKey = userDefaults.string(forKey:UIUtils.PrivateKeySettingsKey)
        
        updateBalanceValueLabel()
        scheduleBalanceUpdating{}

        if isAuthorized && loginCompletionAction != nil {
            loginCompletionAction!()
            loginCompletionAction = nil
        }
    }

    // MARK: Internal methods and properties
    
    fileprivate func handleOrderSubmission(withCryptocurrencyAmount amount:Double,
                                           price:Double,
                                           mode:OrderMode) {
        let timeout = orderView!.isFirstResponder ? UIDefaults.DefaultAnimationDuration : 0
        _ = orderView!.resignFirstResponder()
        let orderCurrency = currentOrderCurrency
        let pair = currentPair
        
        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + timeout) {
            [weak self] in
            self!.animateOrderSubmitting(withOrderView:self!.orderView!,
                                         forMode:mode,
                                         completion: {
                [weak self] in
                let orderPostingMethod = mode == .Buy
                                                 ? self!.btcTradeUAOrderProvider.performBuyOrderAsync
                                                 : self!.btcTradeUAOrderProvider.performSellOrderAsync
                                            
                orderPostingMethod(orderCurrency!,
                                   amount,
                                   price,
                                   self!.publicKey!,
                                   self!.privateKey!,
                                   {
                    [weak self] (orderId) in
                    DispatchQueue.main.async {
                        if orderId == nil {
                            return
                        }
                                        
                        self!.coreDataFacade!.makeOrder(withInitializationBlock: { (order) in
                            order.id = orderId
                            order.isBuy = mode == .Buy
                            order.currency = pair.rawValue as String
                            order.date = Date()
                            order.initialAmount = amount
                            order.price = price
                        })
                                        
                        let orderStatus = OrderStatusInfo(id:orderId!,
                                                          status:OrderStatus.Pending,
                                                          date:Date(),
                                                          currency:orderCurrency!,
                                                          initialAmount:amount,
                                                          remainingAmount:amount,
                                                          price:price,
                                                          type:mode == .Buy ? OrderType.Buy : OrderType.Sell)
                        self!.set(orderStatusInfo:orderStatus, forCurrencyPair:pair)
                        self!.userOrdersView.reloadData()
                                        
                        self!.handleOrdersStatusUpdating {}
                        self!.chartController.reloadData()
                    }
                })
            })
        }
    }
    
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
                    if (self != nil) && (!balanceItems.isEmpty) {
                        self!.balance = balanceItems
                        self!.currenciesController.collectionView!.reloadData()
                        
                        self!.coreDataFacade?.updateStoredBalance(withBalanceItems: balanceItems)
        
                        if (self!.orderView?.superview == nil) {
                            self!.updateBalanceValueLabel()
                        }
                    }
                    
                    onCompletion()
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
        handlePropertyUpdating(withBlock: { (currencyPair, completionHandler) in
            updateOrdersStatus(forCurrencyPair:currencyPair, onCompletion:completionHandler)
        }, onCompletion:onCompletion)
    }
    
    fileprivate func updateOrdersStatus(forCurrencyPair currencyPair:BTCTradeUACurrencyPair,
                                        onCompletion:@escaping () -> Void) {
        if let orders = coreDataFacade?.orders(forCurrencyPair:currencyPair.rawValue as String) {
            let requiredOrdersCount = orders.count
            var ordersCount = 0
            
            if requiredOrdersCount == 0 {
                onCompletion()
            }
            
            let completionHandler = {
                ordersCount += 1
                if ordersCount == requiredOrdersCount {
                    onCompletion()
                }
            }
            
            for order in orders {
                if order.id == nil || publicKey == nil || privateKey == nil {
                    continue
                }

                btcTradeUAOrdersStatusProvider.retrieveStatusAsync(forOrderWithID:order.id!,
                                                                   publicKey:publicKey!,
                                                                   privateKey:privateKey!,
                                                                   onCompletion: { (status) in
                    DispatchQueue.main.async { [weak self] in
                        if (self == nil || status == nil) {
                            return
                        }

                        self!.set(orderStatusInfo:status, forCurrencyPair:currencyPair)

                        if !self!.userOrdersView.isEditing {
                            self!.userOrdersView.reloadData()
                        }
                        
                        completionHandler()
                    }
                })
            }
        }
    }

    fileprivate func set(orderStatusInfo statusInfo:OrderStatusInfo?,
                         forCurrencyPair currencyPair:BTCTradeUACurrencyPair) {
        if statusInfo == nil {
            return
        }

        if (self.currencyPairToUserOrdersStatusMap[currencyPair] == nil) {
            self.currencyPairToUserOrdersStatusMap[currencyPair] = [OrderStatusInfo]()
        }

        var ordersForCurrencyPair = self.currencyPairToUserOrdersStatusMap[currencyPair]
        if let existingOrderIndex = ordersForCurrencyPair?.index(where: { (currentOrder) -> Bool in
            return currentOrder.id == statusInfo!.id
        }) {
            ordersForCurrencyPair![existingOrderIndex] = statusInfo!
        }
        else {
            ordersForCurrencyPair!.append(statusInfo!)
        }

        self.currencyPairToUserOrdersStatusMap[currencyPair] = ordersForCurrencyPair
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
        handlePropertyUpdating(withBlock: { (currencyPair, completionHandler) in
            handleOrdersUpdating(forPair:currencyPair, onCompletion:completionHandler)
        }, onCompletion:onCompletion)
    }
    
    fileprivate func handleOrdersUpdating(forPair pair:BTCTradeUACurrencyPair,
                                          onCompletion:@escaping () -> Void) {
        let RequiredOperationsCount = 2
        var operationsCount = 0
        
        let completionHandler:() -> Void = {
            operationsCount += 1
            
            if operationsCount == RequiredOperationsCount {
                onCompletion()
            }
        }
        
        btcTradeUAOrderProvider.retrieveBuyOrdersAsync(forPair:pair,
                                                       withCompletionHandler: { (orders) in
                                                        DispatchQueue.main.async {
            [weak self] () in
                if (self != nil) {
                    self!.currencyPairToBuyOrdersMap[pair] = orders
                    
                    if pair == self!.currentPair {
                        UIUtils.blink(aboveView:self!.ordersStackController.view)
                        self!.ordersStackController.reloadData()
                    }
                }
                                                            
                completionHandler()
            }
        })

        btcTradeUAOrderProvider.retrieveSellOrdersAsync(forPair:pair,
                                                        withCompletionHandler: { (orders) in
                                                            DispatchQueue.main.async {
            [weak self] () in
                if (self != nil) {
                    self!.currencyPairToSellOrdersMap[pair] = orders
                    self!.ordersStackController.reloadData()
                }
                                                                
                completionHandler()
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
        handlePropertyUpdating(withBlock: { (currencyPair, completionHandler) in
            handleDealsUpdating(forPair:currencyPair, onCompletion:completionHandler)
        }, onCompletion:onCompletion)
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
                }
                
                onCompletion()
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
        handlePropertyUpdating(withBlock: { (currencyPair, completionHandler) in
            handleCandlesUpdatingFor(pair:currencyPair, onCompletion:completionHandler)
        }, onCompletion:onCompletion)
    }

typealias CompletionHandler = () -> Void

    fileprivate func handlePropertyUpdating(withBlock block:(BTCTradeUACurrencyPair, @escaping CompletionHandler) -> Void,
                                            onCompletion:@escaping () -> Void) {
        var operationsCount = 0

        let completionHandler = {
            operationsCount += 1

            if operationsCount == MainViewController.SupportedCurrencyPairs.count {
                onCompletion()
            }
        }

        for currencyPair in MainViewController.SupportedCurrencyPairs {
            block(currencyPair, completionHandler)
        }
    }

    fileprivate func handleCandlesUpdatingFor(pair:BTCTradeUACurrencyPair,
                                              onCompletion:@escaping () -> Void) {
        btcTradeUACandlesProvider.retrieveCandlesAsync(forPair:pair) { (candles) in
            DispatchQueue.main.async { [weak self] () in
                if self != nil {
                    self!.currencyPairToCandlesMap[pair] = candles
                    self!.chartController.reloadData()
                }
                
                onCompletion()
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
            if (self != nil) && sender.isRefreshing {
                    sender.endRefreshing()
            }
        }
    }
    
    fileprivate func loadStoredBalance() {
        let balanceData = self.coreDataFacade!.allBalanceItems()
        let tempArray = NSMutableArray()
        
        for item in balanceData {
            let currency = Currency(rawValue: item.currency! as Currency.RawValue)
            tempArray.add(BalanceItem(currency: currency!, amount: item.amount))
            print("LOAD CoreData balance currency \(item.currency!) = \(item.amount)")
        }
        
        self.balance = tempArray as! [BalanceItem]
        self.currenciesController.collectionView!.reloadData()
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
                         mode:OrderMode) {
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
    
    @objc fileprivate func settingsButtonPressed(button:UIButton) {
        performSegue(withIdentifier:MainViewController.ShowAccountSettingsSegueName, sender:self)
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
    fileprivate var coreDataFacade:CoreDataFacade?
    fileprivate var currencyPairToUserOrdersStatusMap = [BTCTradeUACurrencyPair : [OrderStatusInfo]]()

    fileprivate var publicKey:String?
    fileprivate var privateKey:String?

typealias LoginCompletionAction = () -> Void

    fileprivate var loginCompletionAction:LoginCompletionAction?

    fileprivate static let BalancePollTimeout:TimeInterval = 20
    fileprivate static let PricePollTimeout:TimeInterval = 10
    fileprivate static let CandlesPollTimeout:TimeInterval = 30
    fileprivate static let OrdersPollTimeout:TimeInterval = 10
    fileprivate static let PullDownRefreshingTimeout:TimeInterval = 5

    fileprivate static let SupportedCurrencyPairs = [BTCTradeUACurrencyPair.BtcUah,
                                                     BTCTradeUACurrencyPair.EthUah,
                                                     BTCTradeUACurrencyPair.LtcUah,
                                                     BTCTradeUACurrencyPair.XmrUah,
                                                     BTCTradeUACurrencyPair.DogeUah,
                                                     BTCTradeUACurrencyPair.DashUah,
                                                     BTCTradeUACurrencyPair.SibUah,
                                                     BTCTradeUACurrencyPair.KrbUah,
                                                     BTCTradeUACurrencyPair.ZecUah,
                                                     BTCTradeUACurrencyPair.BchUah,
                                                     BTCTradeUACurrencyPair.EtcUah,
                                                     BTCTradeUACurrencyPair.NvcUah]
    fileprivate static let CurrencyToCurrencyPairMap = [Currency.BTC : BTCTradeUACurrencyPair.BtcUah,
                                                        Currency.ETH : BTCTradeUACurrencyPair.EthUah,
                                                        Currency.LTC : BTCTradeUACurrencyPair.LtcUah,
                                                        Currency.XMR : BTCTradeUACurrencyPair.XmrUah,
                                                        Currency.DOGE : BTCTradeUACurrencyPair.DogeUah,
                                                        Currency.DASH : BTCTradeUACurrencyPair.DashUah,
                                                        Currency.SIB : BTCTradeUACurrencyPair.SibUah,
                                                        Currency.KRB : BTCTradeUACurrencyPair.KrbUah,
                                                        Currency.ZEC : BTCTradeUACurrencyPair.ZecUah,
                                                        Currency.BCH : BTCTradeUACurrencyPair.BchUah,
                                                        Currency.ETC : BTCTradeUACurrencyPair.EtcUah,
                                                        Currency.NVC : BTCTradeUACurrencyPair.NvcUah]

    fileprivate static let ShowAccountSettingsSegueName = "Show Account Settings"

    fileprivate static let MainTabIndex = 0
    fileprivate static let SettingsTabIndex = 1
}

