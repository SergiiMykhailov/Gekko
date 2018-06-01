//  Created by Sergii Mykhailov on 29/03/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class TradingPlatformController : NSObject {

typealias CompletionHandler = () -> Void
typealias CurrencyPairCompletionHandler = (CurrencyPair) -> Void
typealias BalanceCompletionHandler = (Currency) -> Void

    // MARK: Public methods and properties

    public var onDealsUpdated:CurrencyPairCompletionHandler?
    public var onBuyOrdersUpdated:CurrencyPairCompletionHandler?
    public var onSellOrdersUpdated:CurrencyPairCompletionHandler?
    public var onCandlesUpdated:CurrencyPairCompletionHandler?
    public var onUserOrdersStatusUpdated:CurrencyPairCompletionHandler?
    public var onUserBalanceUpdated:BalanceCompletionHandler?

    public let tradingPlatform:TradingPlatform

    public private(set) var tradingPlatformData =
        MainQueueAccessor<TradingPlatformModel>(element:TradingPlatformModel())

    init(tradingPlatform:TradingPlatform) {
        self.tradingPlatform = tradingPlatform
        self.dealsHandler = TradingPlatformUserDealsHandler(withTradingPlatform:tradingPlatform)

        super.init()

        self.coreDataFacade = CoreDataFacade(completionBlock: { [weak self] in
            DispatchQueue.main.async { [weak self] in
                self?.scheduleOrdersStatusUpdating()
                self?.loadStoredBalance()
            }
        })
    }

    public func start() {
        scheduleOrdersUpdating()
        scheduleDealsUpdating()
        scheduleCandlesUpdating()
        scheduleUserBalanceUpdating()
        scheduleOrdersStatusUpdating()
    }

    public func refreshAll() {
        handleDealsUpdating()
        handleOrdersUpdating()
        handleUserOrdersAndDealsUpdating()
        handleUserBalanceUpdating()
        handleCandlesUpdating()
    }

    public func performBuyOrderAsync(forPair pair:CurrencyPair,
                                     amount:Double,
                                     price:Double,
                                     onCompletion:@escaping OrderCompletionCallback) {
        performOrderAsync(isBuy:true,
                          forPair:pair,
                          amount:amount,
                          price:price,
                          onCompletion:onCompletion)
    }

    public func performSellOrderAsync(forPair pair:CurrencyPair,
                                     amount:Double,
                                     price:Double,
                                     onCompletion:@escaping OrderCompletionCallback) {
        performOrderAsync(isBuy:false,
                          forPair:pair,
                          amount:amount,
                          price:price,
                          onCompletion:onCompletion)
    }

    public func cancelOrderAsync(withID orderID:String,
                                 onCompletion:@escaping CancelOrderCompletionCallback) {
        tradingPlatformData.accessInMainQueue { [weak self] (model) in
            for currencyPair in self!.tradingPlatform.supportedCurrencyPairs {
                var currentPairOrders = model.currencyPairToUserOrdersStatusMap[currencyPair]

                if let orderIndex = currentPairOrders?.index(where: { return $0.id == orderID }) {
                    let initialStatus = currentPairOrders![orderIndex].status
                    currentPairOrders![orderIndex].status = .Cancelling

                    self?.onUserOrdersStatusUpdated?(currencyPair)

                    let ordersUpdatingBlock = { (model:TradingPlatformModel) in
                        var updatedOrders = model.currencyPairToUserOrdersStatusMap[currencyPair]
                        updatedOrders = updatedOrders?.filter({ $0.id != orderID })

                        model.currencyPairToUserOrdersStatusMap[currencyPair] = updatedOrders

                        self?.onUserOrdersStatusUpdated?(currencyPair)

                        onCompletion()
                    }

                    if initialStatus == .Pending {
                        self!.tradingPlatform.cancelOrderAsync(withID:orderID,
                                                               onCompletion: { [weak self] in
                                                                self?.tradingPlatformData.accessInMainQueue(withBlock: { (model) in
                                                                    ordersUpdatingBlock(model)
                                                                })
                        })
                    }
                    else if initialStatus == .Rejected {
                        ordersUpdatingBlock(model)
                    }
                }
            }
        }
    }

    // MARK: Internal methods

    fileprivate func performOrderAsync(isBuy:Bool,
                                       forPair pair:CurrencyPair,
                                       amount:Double,
                                       price:Double,
                                       onCompletion:@escaping OrderCompletionCallback) {
        let orderPostingMethod = isBuy ?
                               tradingPlatform.performBuyOrderAsync :
                               tradingPlatform.performSellOrderAsync

        // Assign some dummy ID in order to be able to find this order later.
        let dummyID = UUID().uuidString
        let orderStatus = OrderStatusInfo(id:dummyID,
                                          status:.Publishing,
                                          date:Date(),
                                          currency:pair.secondaryCurrency,
                                          initialAmount:amount,
                                          remainingAmount:amount,
                                          price:price,
                                          type:isBuy ? OrderType.Buy : OrderType.Sell)

        tradingPlatformData.accessInMainQueue(withBlock: { [weak self] (model) in
            model.handle(orderStatusInfo:orderStatus, forCurrencyPair:pair)

            self?.onUserOrdersStatusUpdated?(pair)
        })

        orderPostingMethod(pair, amount, price) { [weak self] (orderID) in
            self?.tradingPlatformData.accessInMainQueue(withBlock: { [weak self] (model) in
                let currencyPairUserOrders = model.currencyPairToUserOrdersStatusMap[pair]

                if let publishingOrderIndex = currencyPairUserOrders?.index(where: { return $0.id == dummyID}) {
                    if orderID != nil {
                        currencyPairUserOrders![publishingOrderIndex].id = orderID!
                        currencyPairUserOrders![publishingOrderIndex].status = .Pending
                    }
                    else {
                        currencyPairUserOrders![publishingOrderIndex].status = .Rejected
                    }

                    self?.onUserOrdersStatusUpdated?(pair)
                }

                self?.handleUserOrdersAndDealsUpdating()

                onCompletion(orderID)
            })
        }
    }

    fileprivate func handlePropertyUpdating(withBlock block:(CurrencyPair) -> Void) {
        for currencyPair in self.tradingPlatform.supportedCurrencyPairs {
            block(currencyPair)
        }
    }

    fileprivate func scheduleCandlesUpdating() {
        handleCandlesUpdating()

        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + TradingPlatformController.PollTimeout) {
            [weak self] () in
            if (self != nil) {
                self!.scheduleCandlesUpdating()
            }
        }
    }

    fileprivate func handleCandlesUpdating() {
        handlePropertyUpdating(withBlock: { (currencyPair) in
            handleCandlesUpdatingFor(pair:currencyPair,
                                     onCompletion: { [weak self] in
                self?.onCandlesUpdated?(currencyPair)
            })
        })
    }

    fileprivate func handleCandlesUpdatingFor(pair:CurrencyPair,
                                              onCompletion:@escaping () -> Void) {
        tradingPlatform.retrieveCandlesAsync(forPair:pair) { [weak self] (candles) in
            self?.tradingPlatformData.accessInMainQueue { (model) in
                model.currencyPairToCandlesMap[pair] = candles

                onCompletion()
            }
        }
    }

    fileprivate func scheduleUserBalanceUpdating() {
        handleUserBalanceUpdating()

        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + TradingPlatformController.PollTimeout) {
            [weak self] () in
            if (self != nil) {
                self!.scheduleUserBalanceUpdating()
            }
        }
    }

    fileprivate func handleUserBalanceUpdating() {
        for supportedCurrency in allCurrencies {
            handleBalanceUpdating(forCurrency:supportedCurrency,
                                  onCompletion: { [weak self] in
                self?.tradingPlatformData.accessInMainQueue(withBlock: { (model) in
                    self?.coreDataFacade?.updateStoredBalance(withBalanceItems:model.balance)
                    self?.onUserBalanceUpdated?(supportedCurrency)
                })
            })
        }
    }

    fileprivate var allCurrencies : [Currency] {
        var result = [Currency]()

        let isCurrencyHandled = { (currency:Currency) -> Bool in
            let isHandled = result.first(where: { $0 == currency} ) != nil
            return isHandled
        }

        for supportedCurrencyPair in tradingPlatform.supportedCurrencyPairs {
            if !isCurrencyHandled(supportedCurrencyPair.primaryCurrency) {
                result.append(supportedCurrencyPair.primaryCurrency)
            }

            if !isCurrencyHandled(supportedCurrencyPair.secondaryCurrency) {
                result.append(supportedCurrencyPair.secondaryCurrency)
            }
        }

        return result
    }

    fileprivate func handleBalanceUpdating(forCurrency currency:Currency,
                                           onCompletion:@escaping () -> Void) {
        tradingPlatform.retriveBalanceAsync(forCurrency:currency) { [weak self] (balance) in
            self?.tradingPlatformData.accessInMainQueue(withBlock: { (model) in
                if balance != nil {
                    if let indexOfBalanceItemForCurrency = model.balance.index(where: { $0.currency == currency }) {
                        model.balance[indexOfBalanceItemForCurrency] = balance!
                    }
                    else {
                        model.balance.append(balance!)
                    }
                }

                onCompletion()
            })
        }
    }

    fileprivate func scheduleOrdersStatusUpdating() {
        handleUserOrdersAndDealsUpdating()

        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + TradingPlatformController.PollTimeout) {
            [weak self] () in
            if (self != nil) {
                self!.scheduleOrdersStatusUpdating()
            }
        }
    }

    fileprivate func handleUserOrdersAndDealsUpdating() {
        handlePropertyUpdating(withBlock: { (currencyPair) in
            updateUserDealsAndOrders(forCurrencyPair:currencyPair,
                                     onCompletion: { [weak self] in
                self?.onUserOrdersStatusUpdated?(currencyPair)
            })
        })
    }

    fileprivate func updateUserDealsAndOrders(forCurrencyPair currencyPair:CurrencyPair,
                                              onCompletion:@escaping () -> Void) {
        tradingPlatform.retrieveUserOrdersAsync(forPair:currencyPair) {
            [weak self] (userOrders) in
            if userOrders != nil {
                self?.tradingPlatformData.accessInMainQueue(withBlock: { (model) in
                    var ordersToApply = userOrders

                    if let currentUserOrders = model.currencyPairToUserOrdersStatusMap[currencyPair] {
                        // There are orders which are stored only on the local device and are not confirmed by server.
                        // These orders should also be presented to user.
                        let publishingOrders = currentUserOrders.filter({ return $0.status == .Publishing })

                        ordersToApply?.append(contentsOf:publishingOrders)

                        // There are orders which are present on server but are marked as 'to be removed' locally.
                        // These orders should not be presented to user.
                        let cancellingOrders = currentUserOrders.filter({ return $0.status == .Cancelling })
                        ordersToApply = ordersToApply?.filter({
                            let remoteOrderID = $0.id
                            let isOrderMarkedForRemoving = cancellingOrders.contains(where:{ return $0.id == remoteOrderID })

                            return !isOrderMarkedForRemoving
                        })
                    }

                    model.currencyPairToUserOrdersStatusMap[currencyPair] = ordersToApply

                    onCompletion()
                })
            }
        }

        let currentMonthDealsHandler = TradingPlatformUserDealsHandler(withTradingPlatform:tradingPlatform)
        handleNextDateRangeForCompletedDeals(forCurrencyPair:currencyPair,
                                             withDealsHandler:currentMonthDealsHandler,
                                             onCompletion:onCompletion)

        handleNextDateRangeForCompletedDeals(forCurrencyPair:currencyPair,
                                             withDealsHandler:dealsHandler,
                                             onCompletion:onCompletion)
    }

    fileprivate func handleNextDateRangeForCompletedDeals(forCurrencyPair currencyPair:CurrencyPair,
                                                          withDealsHandler handler:TradingPlatformUserDealsHandler,
                                                          onCompletion:@escaping () -> Void) {
        handler.handleNextDateRange(forCurrencyPair:currencyPair) {
            [weak self] (completedDeals) in
            self?.tradingPlatformData.accessInMainQueue(withBlock: { (model) in
                if completedDeals != nil {
                    var currencyPairDeals = model.currencyPairToUserDealsMap[currencyPair]

                    if currencyPairDeals != nil {
                        // Single date range may be handled multiple times.
                        // Thus we need to ensure that orders are displayed only once.
                        for deal in completedDeals! {
                            if !currencyPairDeals!.contains(where: { return $0.id == deal.id }) {
                                currencyPairDeals?.insert(deal, at:0)
                            }
                        }
                    }
                    else {
                        currencyPairDeals = completedDeals!
                    }

                    currencyPairDeals?.sort(by: { return $0.date.compare($1.date) == .orderedDescending })

                    model.currencyPairToUserDealsMap[currencyPair] = currencyPairDeals
                }

                onCompletion()
            })
        }
    }

    fileprivate func scheduleOrdersUpdating() {
        handleOrdersUpdating()

        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + TradingPlatformController.PollTimeout) {
            [weak self] () in
            if (self != nil) {
                self!.scheduleOrdersUpdating()
            }
        }
    }

    fileprivate func handleOrdersUpdating() {
        handlePropertyUpdating(withBlock: { (currencyPair) in
            handleOrdersUpdating(forPair:currencyPair,
                                 onCompletion: { [weak self] in
                self?.onBuyOrdersUpdated?(currencyPair)
                self?.onSellOrdersUpdated?(currencyPair)
            })
        })
    }

    fileprivate func handleOrdersUpdating(forPair pair:CurrencyPair,
                                          onCompletion:@escaping () -> Void) {
        let RequiredOperationsCount = UInt32(2)
        let callbacksWaiter = MultiCallbacksWaiter(withNumberOfInvokations:RequiredOperationsCount,
                                                   onCompletion:onCompletion)

        tradingPlatform.retrieveBuyOrdersAsync(forPair:pair,
                                               onCompletion: { [weak self] (orders) in
            self?.tradingPlatformData.accessInMainQueue(withBlock: { (model) in
                model.currencyPairToBuyOrdersMap[pair] = orders

                callbacksWaiter.handleCompletion()
            })
        })

        tradingPlatform.retrieveSellOrdersAsync(forPair:pair,
                                                onCompletion: { [weak self] (orders) in
            self?.tradingPlatformData.accessInMainQueue(withBlock: { (model) in
                model.currencyPairToSellOrdersMap[pair] = orders

                callbacksWaiter.handleCompletion()
            })
        })
    }

    fileprivate func scheduleDealsUpdating() {
        handleDealsUpdating()

        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + TradingPlatformController.PollTimeout) {
            [weak self] () in
            if (self != nil) {
                self!.scheduleDealsUpdating()
            }
        }
    }

    fileprivate func handleDealsUpdating() {
        handlePropertyUpdating(withBlock: { (currencyPair) in
            handleDealsUpdating(forPair:currencyPair,
                                onCompletion: { [weak self] in
                self?.onDealsUpdated?(currencyPair)
            })
        })
    }

    fileprivate func handleDealsUpdating(forPair pair:CurrencyPair,
                                         onCompletion:@escaping () -> Void) {
        tradingPlatform.retrieveDealsAsync(forPair:pair,
                                           onCompletion: { (deals, candle) in
            self.tradingPlatformData.accessInMainQueue(withBlock: { (model) in
                model.currencyPairToDealsMap[pair] = candle

                onCompletion()
            })
        })
    }

    fileprivate func loadStoredBalance() {
        let balanceData = self.coreDataFacade!.allBalanceItems()
        let tempArray = NSMutableArray()

        for item in balanceData {
            let currency = Currency(rawValue: item.currency! as Currency.RawValue)
            tempArray.add(BalanceItem(currency: currency!, amount: item.amount))
        }

        self.tradingPlatformData.accessInMainQueue { (model) in
            model.balance = tempArray as! [BalanceItem]
        }
    }

    // MARK: Internal fields

    fileprivate var coreDataFacade:CoreDataFacade?

    fileprivate let dealsHandler:TradingPlatformUserDealsHandler

    fileprivate static let PollTimeout:TimeInterval = 10
}
