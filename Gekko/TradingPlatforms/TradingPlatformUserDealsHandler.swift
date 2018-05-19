//  Created by Sergii Mykhailov on 22/04/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class TradingPlatformUserDealsHandler : NSObject {

    // MARK: Public methods and properties

    init(withTradingPlatform tradingPlatform:TradingPlatform) {
        self.tradingPlatform = tradingPlatform
    }

    public func handleNextDateRange(forCurrencyPair currencyPair:CurrencyPair,
                                    onCompletion:@escaping UserDealsCallback) {
        if isHandling {
            onCompletion(nil)
            return
        }

        if let dateRange = dateRange(forCurrencyPair:currencyPair) {
            tradingPlatform.retrieveUserDealsAsync(forPair:currencyPair,
                                                   fromDate:dateRange.begin,
                                                   toDate:dateRange.end) {
                [weak self] (dealsCollection) in
                if self != nil && dealsCollection != nil {
                    self!.currencyPairToLastHandledDateRangeMap[currencyPair] = dateRange
                }

                onCompletion(dealsCollection)
            }
        }
    }

    // MARK: Internal methods

    fileprivate func dateRange(forCurrencyPair currencyPair:CurrencyPair) -> DateRange? {
        var result:DateRange? = nil

        if let currencyPairCurrentDateRange = currencyPairToLastHandledDateRangeMap[currencyPair] {
            let dateRange = TradingPlatformUserDealsHandler.nextDateRange(forRange:currencyPairCurrentDateRange)
            if dateRange.begin > TradingPlatformUserDealsHandler.MinDate {
                result = dateRange
            }
        }
        else {
            var dateComponents = Calendar.current.dateComponents(in:TimeZone(secondsFromGMT:0)!, from:Date())
            dateComponents.day = 1
            dateComponents.hour = 0
            dateComponents.minute = 0
            dateComponents.second = 0

            // Begin corresponds to the first day of current month.
            let begin = Calendar.current.date(from:dateComponents)!

            // End corresponds to 'couple days in future'.
            // We need to take more than 1 day into consideration because adding 1 day to
            // current date may still keep us within the same day. It happens due to time zones.
            // Thus the simplies way is to take couple days ahead which definitely takes us
            // outside the bounds of current date's day.
            let end = Calendar.current.date(byAdding:Calendar.Component.day, value:2, to:Date())!

            let currentDateRange = DateRange(begin:begin, end:end)
            result = currentDateRange

            currencyPairToLastHandledDateRangeMap[currencyPair] = result
        }

        return result
    }

    fileprivate static func nextDateRange(forRange range:DateRange) -> DateRange {
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from:range.begin)

        if dateComponents.month! > 1 {
            dateComponents.month! = dateComponents.month! - 1
        }
        else {
            dateComponents.year! = dateComponents.year! - 1
            dateComponents.month = 12
        }

        let beginDate = Calendar.current.date(from:dateComponents)

        let monthDaysRange = Calendar.current.range(of:.day, in:.month, for:beginDate!)
        let numberOfDaysInMonth = monthDaysRange!.count

        dateComponents.day = numberOfDaysInMonth

        let endDate = Calendar.current.date(from:dateComponents)

        return DateRange(begin:beginDate!, end:endDate!)
    }

    fileprivate static func initialDate() -> Date {
        var bitcoinReleaseDate = DateComponents()

        bitcoinReleaseDate.year = 2009
        bitcoinReleaseDate.month = 1
        bitcoinReleaseDate.day = 1

        return Calendar.current.date(from:bitcoinReleaseDate)!
    }

    // MARK: Internal fields

    fileprivate var tradingPlatform:TradingPlatform

    struct DateRange {
        var begin:Date
        var end:Date
    }

    fileprivate var currencyPairToLastHandledDateRangeMap = [CurrencyPair : DateRange]()
    fileprivate var isHandling = false

    fileprivate static let MinDate = initialDate()
}
