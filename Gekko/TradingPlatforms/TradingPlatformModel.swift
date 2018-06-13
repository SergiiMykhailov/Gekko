//  Created by Sergii Mykhailov on 29/03/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

typealias CompletionHandler = () -> Void
typealias CurrencyPairCompletionHandler = (CurrencyPair) -> Void
typealias BalanceCompletionHandler = (Currency) -> Void

class TradingPlatformModel : NSObject,
                             TradingPlatformReadonlyThreadsafeModel {

    // MARK: Public methods and properties

    public var onDealsUpdated:CurrencyPairCompletionHandler?
    public var onBuyOrdersUpdated:CurrencyPairCompletionHandler?
    public var onSellOrdersUpdated:CurrencyPairCompletionHandler?
    public var onCandlesUpdated:CurrencyPairCompletionHandler?
    public var onUserOrdersStatusUpdated:CurrencyPairCompletionHandler?
    public var onUserDealsUpdated:CurrencyPairCompletionHandler?
    public var onUserBalanceUpdated:BalanceCompletionHandler?

    public func allBalanceItems(handlingBlock:@escaping ([BalanceItem]) -> Void) {
        balance.accessInMainQueueReadonly { (balanceItems) in
            handlingBlock(balanceItems)
        }
    }

    public func assign(balanceItem:BalanceItem,
                       completion:@escaping CompletionBlock) {
        balance.accessInMainQueueMutable(withBlock: { (balanceItems) in
            if let itemIndex = balanceItems.index(where: {$0.currency == balanceItem.currency }) {
                balanceItems[itemIndex] = balanceItem
            }
            else {
                balanceItems.append(balanceItem)
            }
        },
                                         completion: { [weak self] in
            self?.onUserBalanceUpdated?(balanceItem.currency)
            completion()
        })
    }

    public func allDealsRange(forCurrencyPair currencyPair:CurrencyPair,
                              handlingBlock:@escaping (CandleInfo?) -> Void) {
        currencyPairToDealsMap.accessInMainQueueReadonly { (map) in
            handlingBlock(map[currencyPair])
        }
    }

    public func assign(allDealsRange:CandleInfo,
                       forCurrencyPair currencyPair:CurrencyPair,
                       completion:@escaping CompletionBlock) {
        currencyPairToDealsMap.accessInMainQueueMutable( withBlock: { (map) in
            map[currencyPair] = allDealsRange
        },
                                                         completion: { [weak self] in
            self?.onDealsUpdated?(currencyPair)
            completion()
        })
    }

    public func allBuyOrders(forCurrencyPair currencyPair:CurrencyPair,
                             handlingBlock:@escaping ([OrderInfo]?) -> Void) {
        currencyPairToBuyOrdersMap.accessInMainQueueReadonly { (map) in
            handlingBlock(map[currencyPair])
        }
    }

    public func assign(allBuyOrders buyOrders:[OrderInfo],
                       forCurrencyPair currencyPair:CurrencyPair,
                       completion:@escaping CompletionBlock) {
        currencyPairToBuyOrdersMap.accessInMainQueueMutable(withBlock: { (map) in
            map[currencyPair] = buyOrders
        },
                                                            completion: { [weak self] in
            self?.onBuyOrdersUpdated?(currencyPair)
            completion()
        })
    }

    public func allSellOrders(forCurrencyPair currencyPair:CurrencyPair,
                              handlingBlock:@escaping ([OrderInfo]?) -> Void) {
        currencyPairToSellOrdersMap.accessInMainQueueReadonly { (map) in
            handlingBlock(map[currencyPair])
        }
    }

    public func assign(allSellOrders sellOrders:[OrderInfo],
                       forCurrencyPair currencyPair:CurrencyPair,
                       completion:@escaping CompletionBlock) {
        currencyPairToSellOrdersMap.accessInMainQueueMutable(withBlock: { (map) in
            map[currencyPair] = sellOrders
        },
                                                             completion: { [weak self] in
            self?.onSellOrdersUpdated?(currencyPair)
            completion()
        })
    }

    public func candles(forCurrencyPair currencyPair:CurrencyPair,
                        handlingBlock:@escaping ([CandleInfo]?) -> Void) {
        currencyPairToCandlesMap.accessInMainQueueReadonly { (map) in
            handlingBlock(map[currencyPair])
        }
    }

    public func assign(candles:[CandleInfo],
                       forCurrencyPair currencyPair:CurrencyPair,
                       completion:@escaping CompletionBlock) {
        currencyPairToCandlesMap.accessInMainQueueMutable(withBlock: { (map) in
            map[currencyPair] = candles
        },
                                                          completion: { [weak self] in
            self?.onCandlesUpdated?(currencyPair)
            completion()
        })
    }

    public func userOrdersStatus(forCurrencyPair currencyPair:CurrencyPair,
                                 handlingBlock:@escaping ([OrderStatusInfo]?) -> Void) {
        currencyPairToUserOrdersStatusMap.accessInMainQueueReadonly { (map) in
            handlingBlock(map[currencyPair])
        }
    }

    public func assign(orderStatusInfo statusInfo:OrderStatusInfo,
                       forCurrencyPair currencyPair:CurrencyPair,
                       completion:@escaping CompletionHandler) {
        currencyPairToUserOrdersStatusMap.accessInMainQueueMutable(withBlock: { (map) in
            if (map[currencyPair] == nil) {
                map[currencyPair] = [OrderStatusInfo]()
            }

            var ordersForCurrencyPair = map[currencyPair]
            if let existingOrderIndex = ordersForCurrencyPair?.index(where: { (currentOrder) -> Bool in
                return currentOrder.id == statusInfo.id
            }) {
                if statusInfo.status == .Pending {
                    ordersForCurrencyPair![existingOrderIndex] = statusInfo
                }
                else {
                    ordersForCurrencyPair!.remove(at:existingOrderIndex)
                }
            }
            else if statusInfo.status == .Pending ||
                statusInfo.status == .Publishing ||
                statusInfo.status == .Cancelling {
                ordersForCurrencyPair!.append(statusInfo)
            }

            map[currencyPair] = ordersForCurrencyPair
        },
                                                                   completion: { [weak self] in
            self?.onUserOrdersStatusUpdated?(currencyPair)
            completion()
        })
    }

    public func assign(userOrders:[OrderStatusInfo],
                       forCurrencyPair currencyPair:CurrencyPair,
                       completion:@escaping CompletionBlock) {
        var ordersToApply = userOrders

        currencyPairToUserOrdersStatusMap.accessInMainQueueMutable(withBlock: { (map) in
            if let currentUserOrders = map[currencyPair] {
                // There are orders which are stored only on the local device and are not confirmed by server.
                // These orders should also be presented to user.
                let publishingOrders = currentUserOrders.filter({ return $0.status == .Publishing })

                ordersToApply.append(contentsOf:publishingOrders)

                // There are orders which are present on server but are marked as 'to be removed' locally.
                // These orders should not be presented to user.
                let cancellingOrders = currentUserOrders.filter({ return $0.status == .Cancelling })
                ordersToApply = ordersToApply.filter({
                    let remoteOrderID = $0.id
                    let isOrderMarkedForRemoving = cancellingOrders.contains(where:{ return $0.id == remoteOrderID })

                    return !isOrderMarkedForRemoving
                })
            }

            map[currencyPair] = ordersToApply
        },
                                                                   completion: { [weak self] in
            self?.onUserOrdersStatusUpdated?(currencyPair)
            completion()
        })
    }

    public func userOrderStatus(forOrderWithID orderID:String,
                                handlingBlock:@escaping (OrderStatus?) -> Void) {
        currencyPairToUserOrdersStatusMap.accessInMainQueueReadonly { (map) in
            for (_, currencyPairOrdersStatusList) in map {
                if let orderIndex = currencyPairOrdersStatusList.index(where: { return $0.id == orderID }) {
                    let status = currencyPairOrdersStatusList[orderIndex].status
                    handlingBlock(status)

                    return
                }
            }

            handlingBlock(nil)
        }
    }

    public func assign(userOrderStatus status:OrderStatus,
                       toOrderWithID orderID:String,
                       completion:@escaping CompletionHandler) {
        var affectedCurrencyPair:CurrencyPair?

        currencyPairToUserOrdersStatusMap.accessInMainQueueMutable(withBlock: { (map) in
            for (currencyPair, currencyPairOrdersStatusList) in map {
                if let orderIndex = currencyPairOrdersStatusList.index(where: { return $0.id == orderID }) {
                    currencyPairOrdersStatusList[orderIndex].status = status
                    affectedCurrencyPair = currencyPair
                    return
                }
            }
        },
                                                                   completion: { [weak self] in
            if affectedCurrencyPair != nil {
                self?.onUserOrdersStatusUpdated?(affectedCurrencyPair!)
            }

            completion()
        })
    }

    public func assignOrderID(ofOrderWithID orderID:String,
                              toOrderID newOrderID:String,
                              completion:@escaping CompletionBlock) {
        var affectedCurrencyPair:CurrencyPair?

        currencyPairToUserOrdersStatusMap.accessInMainQueueMutable(withBlock: { (map) in
            for (currencyPair, currencyPairOrdersStatusList) in map {
                if let orderIndex = currencyPairOrdersStatusList.index(where: { return $0.id == orderID }) {
                    currencyPairOrdersStatusList[orderIndex].id = newOrderID
                    affectedCurrencyPair = currencyPair
                    return
                }
            }
        },
                                                                   completion: { [weak self] in
            if affectedCurrencyPair != nil {
                self?.onUserOrdersStatusUpdated?(affectedCurrencyPair!)
            }

            completion()
        })
    }

    public func userDeals(forCurrencyPair currencyPair:CurrencyPair,
                          handlingBlock:@escaping ([OrderStatusInfo]?) -> Void) {
        currencyPairToUserDealsMap.accessInMainQueueReadonly { (map) in
            handlingBlock(map[currencyPair])
        }
    }

    public func assign(userDeals:[OrderStatusInfo],
                       forCurrencyPair currencyPair:CurrencyPair,
                       completion:@escaping CompletionBlock) {
        currencyPairToUserDealsMap.accessInMainQueueMutable(withBlock: { (map) in
            var currencyPairDeals = map[currencyPair]

            if currencyPairDeals != nil {
                // Single date range may be handled multiple times.
                // Thus we need to ensure that orders are displayed only once.
                for deal in userDeals {
                    if !currencyPairDeals!.contains(where: { return $0.id == deal.id }) {
                        currencyPairDeals?.insert(deal, at:0)
                    }
                }
            }
            else {
                currencyPairDeals = userDeals
            }

            currencyPairDeals?.sort(by: { return $0.date.compare($1.date) == .orderedDescending })

            map[currencyPair] = currencyPairDeals
        },
                                                            completion: { [weak self] in
            self?.onUserDealsUpdated?(currencyPair)
            completion()
        })
    }

    // MARK: Internal fields

    fileprivate var currencyPairToDealsMap = MainQueueAccessor<[CurrencyPair : CandleInfo]>(element:[CurrencyPair : CandleInfo]())
    fileprivate var currencyPairToBuyOrdersMap = MainQueueAccessor<[CurrencyPair : [OrderInfo]]>(element:[CurrencyPair : [OrderInfo]]())
    fileprivate var currencyPairToSellOrdersMap = MainQueueAccessor<[CurrencyPair : [OrderInfo]]>(element:[CurrencyPair : [OrderInfo]]())
    fileprivate var currencyPairToCandlesMap = MainQueueAccessor<[CurrencyPair : [CandleInfo]]>(element:[CurrencyPair : [CandleInfo]]())
    fileprivate var currencyPairToUserOrdersStatusMap = MainQueueAccessor<[CurrencyPair : [OrderStatusInfo]]>(element:[CurrencyPair : [OrderStatusInfo]]())
    fileprivate var currencyPairToUserDealsMap = MainQueueAccessor<[CurrencyPair : [OrderStatusInfo]]>(element:[CurrencyPair : [OrderStatusInfo]]())
    fileprivate var balance = MainQueueAccessor<[BalanceItem]>(element:[BalanceItem]())
}
