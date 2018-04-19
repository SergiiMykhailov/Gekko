//  Created by Sergii Mykhailov on 29/03/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class TradingPlatformController : NSObject {

typealias CompletionHandler = () -> Void

    // MARK: Public methods and properties

    public var onCompletedOrdersUpdated:CompletionHandler?
    public var onBuyOrdersUpdated:CompletionHandler?
    public var onSellOrdersUpdated:CompletionHandler?
    public var onCandlesUpdated:CompletionHandler?
    public var onUserOrdersStatusUpdated:CompletionHandler?
    public var onBalanceUpdated:CompletionHandler?

    public let tradingPlatform:TradingPlatform

    public private(set) var tradingPlatformData =
        MainQueueAccessor<TradingPlatformModel>(element:TradingPlatformModel())

    init(tradingPlatform:TradingPlatform) {
        self.tradingPlatform = tradingPlatform

        super.init()

        coreDataFacade = CoreDataFacade(completionBlock: { [weak self] in
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
        scheduleBalanceUpdating{}
        scheduleOrdersStatusUpdating()
    }

    public func refreshAll(withCompletion completion:@escaping CompletionHandler) {
        let callbacksWaiter = MultiCallbacksWaiter(withNumberOfInvokations:5, onCompletion:completion)

        handleDealsUpdating(onCompletion:{ callbacksWaiter.handleCompletion() })
        handleOrdersUpdating(onCompletion:{ callbacksWaiter.handleCompletion() })
        handleOrdersStatusUpdating(onCompletion:{ callbacksWaiter.handleCompletion() })
        scheduleBalanceUpdating(onCompletion:{ callbacksWaiter.handleCompletion() })
        handleCandlesUpdating(onCompletion:{ callbacksWaiter.handleCompletion() })
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
                currentPairOrders = currentPairOrders?.filter({ (currentOrderStatus) -> Bool in
                    currentOrderStatus.id != orderID
                })

                model.currencyPairToUserOrdersStatusMap[currencyPair] = currentPairOrders
            }

            self!.tradingPlatform.cancelOrderAsync(withID:orderID, onCompletion:onCompletion)
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

        orderPostingMethod(pair, amount, price) { [weak self] (orderID) in
            self?.coreDataFacade!.makeOrder(withInitializationBlock: { (order) in
                order.id = orderID!
                order.isBuy = isBuy
                order.currency = pair.secondaryCurrency.rawValue as String
                order.date = Date()
                order.initialAmount = amount
                order.price = price
            })

            self?.tradingPlatformData.accessInMainQueue(withBlock: { [weak self] (model) in
                let orderStatus = OrderStatusInfo(id:orderID!,
                                                  status:OrderStatus.Pending,
                                                  date:Date(),
                                                  currency:pair.secondaryCurrency,
                                                  initialAmount:amount,
                                                  remainingAmount:amount,
                                                  price:price,
                                                  type:isBuy ? OrderType.Buy : OrderType.Sell)

                model.set(orderStatusInfo:orderStatus, forCurrencyPair:pair)

                self?.handleOrdersStatusUpdating {}

                onCompletion(orderID)
            })
        }
    }

    fileprivate func handlePropertyUpdating(withBlock block:(CurrencyPair, @escaping CompletionHandler) -> Void,
                                            onCompletion:@escaping CompletionHandler) {
        let callbacksWaiter = MultiCallbacksWaiter(withNumberOfInvokations:UInt32(self.tradingPlatform.supportedCurrencyPairs.count),
                                                   onCompletion:onCompletion)

        for currencyPair in self.tradingPlatform.supportedCurrencyPairs {
            block(currencyPair, { callbacksWaiter.handleCompletion() })
        }
    }

    fileprivate func scheduleCandlesUpdating() {
        handleCandlesUpdating(onCompletion: { [weak self] in
            if self != nil {
                DispatchQueue.main.async {
                    self?.onCandlesUpdated?()
                }
            }
        })

        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + TradingPlatformController.PollTimeout) {
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

    fileprivate func handleCandlesUpdatingFor(pair:CurrencyPair,
                                              onCompletion:@escaping () -> Void) {
        tradingPlatform.retrieveCandlesAsync(forPair:pair) { [weak self] (candles) in
            self?.tradingPlatformData.accessInMainQueue { (model) in
                model.currencyPairToCandlesMap[pair] = candles

                onCompletion()
            }
        }
    }

    fileprivate func scheduleBalanceUpdating(onCompletion:@escaping () -> Void) {
        let callbacksWaiter = MultiCallbacksWaiter(withNumberOfInvokations:UInt32(allCurrencies.count)) {
            [weak self] in
            self?.tradingPlatformData.accessInMainQueue(withBlock: { (model) in
                self?.coreDataFacade?.updateStoredBalance(withBalanceItems:model.balance)
                self?.onBalanceUpdated?()

                onCompletion()
            })
        }

        for supportedCurrency in allCurrencies {
            handleBalanceUpdating(forCurrency:supportedCurrency, onCompletion: {
                callbacksWaiter.handleCompletion()
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
        handleOrdersStatusUpdating(onCompletion: { [weak self] in
            if self != nil {
                self!.onUserOrdersStatusUpdated?()
            }
        })

        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + TradingPlatformController.PollTimeout) {
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

    fileprivate func updateOrdersStatus(forCurrencyPair currencyPair:CurrencyPair,
                                        onCompletion:@escaping () -> Void) {
        if let orders = coreDataFacade?.orders(forCurrencyPair:currencyPair.toString()) {
            let requiredOrdersCount = UInt32(orders.count)

            let callbacksWaiter = MultiCallbacksWaiter(withNumberOfInvokations:requiredOrdersCount,
                                                       onCompletion:onCompletion)

            for order in orders {
                if order.id == nil {
                    continue
                }

                tradingPlatform.retrieveOrderStatusAsync(withID:order.id!, onCompletion: { (status) in
                    DispatchQueue.main.async { [weak self] in
                        if (self == nil || status == nil) {
                            return
                        }

                        self!.tradingPlatformData.accessInMainQueue(withBlock: { (model) in
                            model.set(orderStatusInfo:status!, forCurrencyPair:currencyPair)
                            callbacksWaiter.handleCompletion()
                        })
                    }
                })
            }
        }
    }

    fileprivate func scheduleOrdersUpdating() {
        handleOrdersUpdating(onCompletion: { [weak self] in
            if self != nil {
                self!.onBuyOrdersUpdated?()
                self!.onSellOrdersUpdated?()
            }
        })

        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + TradingPlatformController.PollTimeout) {
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
        handleDealsUpdating(onCompletion:{ [weak self] in
            self?.onCompletedOrdersUpdated?()
        })

        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + TradingPlatformController.PollTimeout) {
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

    fileprivate func handleDealsUpdating(forPair pair:CurrencyPair,
                                         onCompletion:@escaping () -> Void) {
        tradingPlatform.retrieveDealsAsync(forPair:pair,
                                           onCompletion: { (deals, candle) in
            self.tradingPlatformData.accessInMainQueue(withBlock: { (model) in
                model.currencyPairToCompletedOrdersMap[pair] = candle

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

    fileprivate static let PollTimeout:TimeInterval = 10
}
