//  Created by Aleksandr Saliienko on 4/12/18.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

protocol ChangeServerAccessibilityDelegate {
    func setupServerErrorView()
    func removeServerErrorView()
}

class TradingPlatformAccessibilityController {
    
    public var delegate:ChangeServerAccessibilityDelegate?
    
    // MARK: Private methods
    
    public func checkServerStatus() {
        btcTradeUAOrderProvider.retrieveDealsAsync(forPair:BTCTradeUACurrencyPair.BtcUah,
                                                    withCompletionHandler: { (deals, candle) in
            DispatchQueue.main.async { [weak self] () in
                if self != nil {
                    if deals.isEmpty && self!.serverErrorViewInBackground {
                        self!.delegate?.setupServerErrorView()
                        self!.serverErrorViewInBackground = false
                    }
                    else if !deals.isEmpty && !self!.serverErrorViewInBackground {
                        self!.delegate?.removeServerErrorView()
                        self!.serverErrorViewInBackground = true
                    }
                }
            }
        })
    }
    
    // MARK: Internal fields
    
    fileprivate let btcTradeUAOrderProvider = BTCTradeUAOrderProvider()
    
    fileprivate var serverErrorViewInBackground = true
}
