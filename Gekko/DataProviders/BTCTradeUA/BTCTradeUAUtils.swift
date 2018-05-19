//  Created by Sergii Mykhailov on 24/04/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class BTCTradeUAUtils {

    // MARK: Public methods and properties

    public static func publishDate(fromDictionary dictionary:[String : Any]) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier:"en_US")
        dateFormatter.dateFormat = "dd-MMM-yyyy HH:mm:ss"

        var result:Date? = nil

        if let dateString = dictionary[DateKey] as? String {
            var dateStringByReplacingInvalidSymbols = dateString.replacingOccurrences(of:"p.m.", with:"PM")
            dateStringByReplacingInvalidSymbols = dateStringByReplacingInvalidSymbols.replacingOccurrences(of:"a.m.", with:"AM")
            dateStringByReplacingInvalidSymbols = dateStringByReplacingInvalidSymbols.replacingOccurrences(of:"г.", with:"")

            dateStringByReplacingInvalidSymbols = dateStringByReplacingInvalidSymbols.replacingOccurrences(of:"января", with:"January")
            dateStringByReplacingInvalidSymbols = dateStringByReplacingInvalidSymbols.replacingOccurrences(of:"февраля", with:"February")
            dateStringByReplacingInvalidSymbols = dateStringByReplacingInvalidSymbols.replacingOccurrences(of:"марта", with:"March")
            dateStringByReplacingInvalidSymbols = dateStringByReplacingInvalidSymbols.replacingOccurrences(of:"апреля", with:"April")
            dateStringByReplacingInvalidSymbols = dateStringByReplacingInvalidSymbols.replacingOccurrences(of:"мая", with:"May")
            dateStringByReplacingInvalidSymbols = dateStringByReplacingInvalidSymbols.replacingOccurrences(of:"июня", with:"June")
            dateStringByReplacingInvalidSymbols = dateStringByReplacingInvalidSymbols.replacingOccurrences(of:"июля", with:"July")
            dateStringByReplacingInvalidSymbols = dateStringByReplacingInvalidSymbols.replacingOccurrences(of:"августа", with:"August")
            dateStringByReplacingInvalidSymbols = dateStringByReplacingInvalidSymbols.replacingOccurrences(of:"сентября", with:"September")
            dateStringByReplacingInvalidSymbols = dateStringByReplacingInvalidSymbols.replacingOccurrences(of:"октября", with:"October")
            dateStringByReplacingInvalidSymbols = dateStringByReplacingInvalidSymbols.replacingOccurrences(of:"ноября", with:"November")
            dateStringByReplacingInvalidSymbols = dateStringByReplacingInvalidSymbols.replacingOccurrences(of:"декабря", with:"December")

            result = dateFormatter.date(from:dateStringByReplacingInvalidSymbols)

            if result == nil {
                dateFormatter.dateFormat = "MMMM dd, yyyy, h:mm a"
                result = dateFormatter.date(from:dateStringByReplacingInvalidSymbols)
            }

            if result == nil {
                dateFormatter.dateFormat = "MMM. dd, yyyy, h:mm a"
                result = dateFormatter.date(from:dateStringByReplacingInvalidSymbols)
            }

            if result == nil {
                dateFormatter.dateFormat = "dd MMMM yyyy  hh:mm:ss"
                result = dateFormatter.date(from:dateStringByReplacingInvalidSymbols)
            }
        }

        return result
    }

    public static func orderInfo(fromDictionary dictionary:[String : Any]) -> OrderInfo? {
        var result:OrderInfo? = nil

        let traditionalCurrencyAmount = dictionary[TraditionalCurrencyAmountKey] as? String
        let cryptoCurrencyAmount = dictionary[CryptoCurrencyAmountKey] as? String
        let price = dictionary[PriceKey] as? String
        let user = dictionary[UserKey] as? String
        let type = dictionary[DealTypeKey] as? String

        if traditionalCurrencyAmount != nil &&
            cryptoCurrencyAmount != nil &&
            price != nil &&
            type != nil {
            let traditionalCurrencyAmountCasted = Double(traditionalCurrencyAmount!)
            let cryptoCurrencyAmountCasted = Double(cryptoCurrencyAmount!)
            let priceCasted = Double(price!)
            let isBuy = type! == "buy"

            if traditionalCurrencyAmountCasted != nil &&
                cryptoCurrencyAmountCasted != nil &&
                priceCasted != nil {
                result =
                    OrderInfo(fiatCurrencyAmount:traditionalCurrencyAmountCasted!,
                              cryptoCurrencyAmount:cryptoCurrencyAmountCasted!,
                              price:priceCasted!,
                              user:user != nil ? user! : "",
                              isBuy:isBuy)
            }
        }

        return result
    }

    public static func ordersStatus(fromResponseItems items:[String : Any],
                                    withStatus status:OrderStatus) -> [OrderStatusInfo] {
        var result = [OrderStatusInfo]()

        for item in items.enumerated() {
            if let dealsCollection = item.element.value as? [Any] {
                for dealItem in dealsCollection {
                    if let singleDealDictionary = dealItem as? [String : Any] {
                        if let dealInfo = BTCTradeUAUtils.orderInfo(fromDictionary:singleDealDictionary) {
                            if let id = singleDealDictionary[BTCTradeUAUtils.IDKey] as? UInt32 {
                                if let date = BTCTradeUAUtils.publishDate(fromDictionary:singleDealDictionary) {
                                    let itemToInsert = OrderStatusInfo(id:"\(id)",
                                        status:status,
                                        date:date,
                                        currency:.UAH,
                                        initialAmount:dealInfo.cryptoCurrencyAmount,
                                        remainingAmount:0.0,
                                        price:dealInfo.price,
                                        type:dealInfo.isBuy ? OrderType.Buy : OrderType.Sell)

                                    result.append(itemToInsert)
                                }
                            }
                        }
                    }
                }
            }
        }

        return result
    }

    // MARK: Internal fields

    fileprivate static let DateKey = "pub_date"
    fileprivate static let IDKey = "id"
    fileprivate static let TraditionalCurrencyAmountKey = "amnt_base"
    fileprivate static let CryptoCurrencyAmountKey = "amnt_trade"
    fileprivate static let PriceKey = "price"
    fileprivate static let UserKey = "user"
    fileprivate static let DealTypeKey = "type"
}
