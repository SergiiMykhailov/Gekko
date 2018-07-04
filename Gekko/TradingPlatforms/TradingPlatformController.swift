//  Created by Sergii Mykhailov on 29/03/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class TradingPlatformController : NSObject {

    public let tradingPlatform:TradingPlatform

    public var activeCurrencyPair:CurrencyPair? 
    
    public var readonlyModel:TradingPlatformReadonlyThreadsafeModel {
        get {
            return model
        }
    }

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

    public var activeCurrencyPair:CurrencyPair? {
        didSet {
            refreshAll()
        }
    }

    public var notifications:TradingPlatformModelNotifications {
        return TradingPlatformModelNotifications(model:model)
    }

    public func start() {
        scheduleOrdersUpdating()
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
        model.userOrderStatus(forOrderWithID:orderID) { [weak self] (initialStatus) in
            if initialStatus != nil {
                let modelUpdatingBlock:CancelOrderCompletionCallback = { [weak self] in
                    self?.model.assign(userOrderStatus:.Canceled,
                                       toOrderWithID:orderID,
                                       completion:onCompletion)
                }

                if initialStatus! == .Pending {
                    self?.tradingPlatform.cancelOrderAsync(withID:orderID, onCompletion:modelUpdatingBlock)
                }
                else if initialStatus! == .Rejected {
                    modelUpdatingBlock()
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

        model.assign(orderStatusInfo:orderStatus,
                     forCurrencyPair:pair,
                     completion: {
            orderPostingMethod(pair, amount, price) { [weak self] (orderID) in
                let orderStatusUpdatingCompletionBlock = { [weak self] in
                    self?.handleUserOrdersAndDealsUpdating()

                    onCompletion(orderID)
                }

                if orderID != nil {
                    self?.model.assignOrderID(ofOrderWithID:dummyID,
                                              toOrderID:orderID!,
                                              completion: { [weak self] in
                        self?.model.assign(userOrderStatus:.Pending,
                                           toOrderWithID:orderID!,
                                           completion:orderStatusUpdatingCompletionBlock)
                    })
                }
                else {
                    self?.model.assign(userOrderStatus:.Rejected,
                                       toOrderWithID:dummyID,
                                       completion:orderStatusUpdatingCompletionBlock)
                }
            }
        })
    }

    fileprivate func handlePropertyUpdating(forAllCurrencies:Bool = false,
                                            withBlock block:(CurrencyPair) -> Void) {
        if forAllCurrencies {
            for currencyPair in self.tradingPlatform.supportedCurrencyPairs {
                block(currencyPair)
            }
        }
        else if activeCurrencyPair != nil {
            block(activeCurrencyPair!)
        }
    }

    fileprivate func scheduleCandlesUpdating() {
        handleCandlesUpdating()

        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + TradingPlatformController.LongPollTimeout) {
            [weak self] () in
            if (self != nil) {
                self!.scheduleCandlesUpdating()
            }
        }
    }

    fileprivate func handleCandlesUpdating() {
        handlePropertyUpdating(withBlock: { (currencyPair) in
            handleCandlesUpdatingFor(pair:currencyPair,
                                     onCompletion: { })
        })
    }

    fileprivate func handleCandlesUpdatingFor(pair:CurrencyPair,
                                              onCompletion:@escaping () -> Void) {
        tradingPlatform.retrieveCandlesAsync(forPair:pair) { [weak self] (candles) in
            if !candles.isEmpty {
            self?.model.assign(candles:candles,
                               forCurrencyPair:pair,
                               completion:onCompletion)
            }
            else {
                onCompletion()
            }
        }
    }

    fileprivate func scheduleUserBalanceUpdating() {
        handleUserBalanceUpdating()

        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + TradingPlatformController.LongPollTimeout) {
            [weak self] () in
            if (self != nil) {
                self!.scheduleUserBalanceUpdating()
            }
        }
    }

    fileprivate func handleUserBalanceUpdating() {
        for supportedCurrency in allCurrencies {
            handleBalanceUpdating(forCurrency:supportedCurrency,
                                  completion: { [weak self] in
                self?.model.allBalanceItems(handlingBlock: { [weak self] (balanceItems) in
                    self?.coreDataFacade?.updateStoredBalance(withBalanceItems:balanceItems)
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
                                           completion:@escaping () -> Void) {
        tradingPlatform.retriveBalanceAsync(forCurrency:currency) { [weak self] (balance) in
            if balance != nil {
                self?.model.assign(balanceItem:balance!, completion:completion)
            }
            else {
                completion()
            }
        }
    }

    fileprivate func scheduleOrdersStatusUpdating() {
        handleUserOrdersAndDealsUpdating()

        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + TradingPlatformController.DefaultPollTimeout) {
            [weak self] () in
            if (self != nil) {
                self!.scheduleOrdersStatusUpdating()
            }
        }
    }

    fileprivate func handleUserOrdersAndDealsUpdating() {
        handlePropertyUpdating(withBlock: { (currencyPair) in
            updateUserDealsAndOrders(forCurrencyPair:currencyPair,
                                     onCompletion: { })
        })
    }

    fileprivate func updateUserDealsAndOrders(forCurrencyPair currencyPair:CurrencyPair,
                                              onCompletion:@escaping () -> Void) {
        tradingPlatform.retrieveUserOrdersAsync(forPair:currencyPair) {
            [weak self] (userOrders) in
            if userOrders != nil {
                self?.model.assign(userOrders:userOrders!,
                                   forCurrencyPair:currencyPair,
                                   completion:onCompletion)
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
            if completedDeals != nil {
                self?.model.assign(userDeals:completedDeals!, forCurrencyPair:currencyPair, completion:onCompletion)
            }
        }
    }

    fileprivate func scheduleOrdersUpdating() {
        handleOrdersUpdating()

        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + TradingPlatformController.DefaultPollTimeout) {
            [weak self] () in
            if (self != nil) {
                self!.scheduleOrdersUpdating()
            }
        }
    }

    fileprivate func handleOrdersUpdating() {
        handlePropertyUpdating(withBlock: { (currencyPair) in
            handleOrdersUpdating(forPair:currencyPair,
                                 onCompletion: { })
        })
    }

    fileprivate func handleOrdersUpdating(forPair pair:CurrencyPair,
                                          onCompletion:@escaping () -> Void) {
        tradingPlatform.retrieveBuyOrdersAsync(forPair:pair,
                                               onCompletion: { [weak self] (orders) in
            self?.model.assign(allBuyOrders:orders,
                               forCurrencyPair:pair,
                               completion: {
                self?.onBuyOrdersUpdated?(pair)
            })
        })

        tradingPlatform.retrieveSellOrdersAsync(forPair:pair,
                                                onCompletion: { [weak self] (orders) in
            self?.model.assign(allSellOrders:orders,
                               forCurrencyPair:pair,
                               completion: {
                self?.onSellOrdersUpdated?(pair)
            })
        })
    }

    fileprivate func scheduleDealsUpdating() {
        handleDealsUpdating()

        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + TradingPlatformController.DefaultPollTimeout) {
            [weak self] () in
            if (self != nil) {
                self!.scheduleDealsUpdating()
            }
        }
    }

    fileprivate func handleDealsUpdating() {
        handlePropertyUpdating(forAllCurrencies:true,
                               withBlock: { (currencyPair) in
            handleDealsUpdating(forPair:currencyPair,
                                onCompletion: { })
        })
    }

    fileprivate func handleDealsUpdating(forPair pair:CurrencyPair,
                                         onCompletion:@escaping () -> Void) {
        tradingPlatform.retrieveDealsAsync(forPair:pair,
                                           onCompletion: { [weak self] (deals, candle) in
            if candle != nil {
                self?.model.assign(allDealsRange:candle!, forCurrencyPair:pair, completion:onCompletion)
            }
        })
    }

    fileprivate func loadStoredBalance() {
        let balanceData = self.coreDataFacade!.allBalanceItems()

        for item in balanceData {
            let currency = Currency(rawValue: item.currency! as Currency.RawValue)
            model.assign(balanceItem:BalanceItem(currency:currency!, amount:item.amount), completion:{ })
        }
    }

    // MARK: Internal fields

    fileprivate let model = TradingPlatformModel()

    fileprivate var coreDataFacade:CoreDataFacade?

    fileprivate let dealsHandler:TradingPlatformUserDealsHandler

    fileprivate static let DefaultPollTimeout:TimeInterval = 20
    fileprivate static let LongPollTimeout:TimeInterval = 600
}
