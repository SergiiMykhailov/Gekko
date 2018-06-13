//  Created by Aleksandr Saliienko on 4/12/18.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

protocol TradingPlatformAccessibilityControllerDelegate : class {
    func tradingPlatformAccessibilityControllerDidDetectConnectionFailure(_ sender:TradingPlatformAccessibilityController)
    func tradingPlatformAccessibilityControllerDidDetectConnectionRestore(_ sender:TradingPlatformAccessibilityController)
}

class TradingPlatformAccessibilityController {
    
    public weak var delegate:TradingPlatformAccessibilityControllerDelegate?
    
    // MARK: Internal methods
    
    public func checkServerStatus() {
        btcTradeUAOrderProvider.retrieveDealsAsync(forPair:BTCTradeUACurrencyPair.BtcUah,
                                                    withCompletionHandler: { (deals, candle) in
            DispatchQueue.main.async { [weak self] () in
                if self != nil {
                    if deals.isEmpty && self!.connectionEstablished {
                        self!.delegate?.tradingPlatformAccessibilityControllerDidDetectConnectionFailure(self!)
                        self!.connectionEstablished = false
                    }
                    else if !deals.isEmpty && !self!.connectionEstablished {
                        self!.delegate?.tradingPlatformAccessibilityControllerDidDetectConnectionRestore(self!)
                        self!.connectionEstablished = true
                    }
                }
            }
        })
    }
    
    public func startMonitoringAccessibility() {
        checkServerStatus()
        
        DispatchQueue.main.asyncAfter(deadline:DispatchTime.now() + TradingPlatformAccessibilityController.ServerStatusUpdatingTimeout) {
            [weak self] () in
            if (self != nil) {
                self!.startMonitoringAccessibility()
            }
        }
    }
    
    // MARK: Internal fields
    
    fileprivate let btcTradeUAOrderProvider = BTCTradeUAOrderProvider()
    
    fileprivate var connectionEstablished = true
    
    fileprivate static let ServerStatusUpdatingTimeout:TimeInterval = 10
}
