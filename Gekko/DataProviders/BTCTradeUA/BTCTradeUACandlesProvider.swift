//  Created by Sergii Mykhailov on 08/12/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation

class BTCTradeUACandlesProvider : BTCTradeUAProviderBase {

    func retrieveCandlesAsync(forPair pair:BTCTradeUACurrencyPair,
                              withCompletionHandler completionHandler:@escaping ([CandleInfo]) -> Void)
    {
        let dealsSuffix = String(format:"japan_stat/high/%@", pair.rawValue)

        super.performGetRequestAsync(withSuffix:dealsSuffix) { [weak self] (items, _) in
            if (self != nil) {
                let candlesCollection = self!.candles(fromResponseItems:items)

                completionHandler(candlesCollection)
            }
        }
    }

    // MARK: Internal functions

    fileprivate func candles(fromResponseItems items:[String : Any]) -> [CandleInfo] {
        var result = [CandleInfo]()

        let trades = items[BTCTradeUACandlesProvider.TradesKey]
        if trades != nil {
            if let tradesCollection = trades as? [Any] {
                for tradeItem in tradesCollection {
                    if let tradeItemValuesCollection = tradeItem as? [Any] {
                        if (tradeItemValuesCollection.count == BTCTradeUACandlesProvider.TradeItemValuesCount) {
                            let dateValue = tradeItemValuesCollection[0] as? TimeInterval
                            let openPrice = tradeItemValuesCollection[1] as? Double
                            let maxPrice = tradeItemValuesCollection[2] as? Double
                            let minPrice = tradeItemValuesCollection[3] as? Double
                            let closePrice = tradeItemValuesCollection[4] as? Double
                            let volume = tradeItemValuesCollection[5] as? Double

                            if dateValue != nil &&
                               openPrice != nil &&
                               maxPrice != nil &&
                               minPrice != nil &&
                               closePrice != nil &&
                               volume != nil {
                                let secondsSince1970 = Int(dateValue! / 1000)
                                let date = Date(timeIntervalSince1970:TimeInterval(secondsSince1970))

                                result.append(CandleInfo(date:date,
                                                         high:maxPrice!,
                                                         low:minPrice!,
                                                         open:openPrice!,
                                                         close:closePrice!))
                            }
                        }
                    }
                }
            }
        }

        let dailyCandles = join(dailyCandles:result)

        return dailyCandles
    }

    fileprivate func join(dailyCandles candles:[CandleInfo]) -> [CandleInfo] {
        if candles.isEmpty {
            return candles
        }

        var result = [CandleInfo]()

        let calendar = Calendar.current
        let timeZone = TimeZone(secondsFromGMT:0)
        var dailyCandle = candles.first!
        var dailyCandleComponents = calendar.dateComponents(in:timeZone!, from:dailyCandle.date)

        var lastCandleInDay = dailyCandle

        for (index, candle) in candles.enumerated() {
            dailyCandle.low = min(dailyCandle.low, candle.low)
            dailyCandle.high = max(dailyCandle.high, candle.high)

            let candleDateComponents = calendar.dateComponents(in:timeZone!, from:candle.date)
            let isCandleInSameDay = candleDateComponents.day == dailyCandleComponents.day

            if isCandleInSameDay {
                lastCandleInDay = candle

                if index == candles.count - 1 {
                    result.append(dailyCandle)
                }
            }
            else if isCandleInSameDay == false || index == candles.count - 1 {
                dailyCandle.close = lastCandleInDay.close

                result.append(dailyCandle)

                dailyCandle = candle
                dailyCandleComponents = candleDateComponents
                lastCandleInDay = dailyCandle
            }
        }

        return result
    }

    // MARK: Internal fields and properties

    private static let TradesKey = "trades"
    private static let TradeItemValuesCount = 6
}
