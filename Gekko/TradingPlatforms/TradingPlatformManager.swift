//  Created by Sergii Mykhailov on 30/03/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class TradingPlatformManager : NSObject {

    // MARK: Public methods and properties

    public static let shared = TradingPlatformManager()

    public private(set) lazy var tradingPlatform = TradingPlatformManager.createTradingPlatform()

    public func handleRegistration(withServerResponse serverResponse:[String : Any]) {
        let publicKey = TradingPlatformManager.publicKey(fromServerResponse:serverResponse)
        let privateKey = TradingPlatformManager.privateKey(fromServerResponse:serverResponse)

        if publicKey != nil && privateKey != nil {
            let userDefaults = UserDefaults.standard

            userDefaults.setValue(publicKey!, forKey:UIUtils.PublicKeySettingsKey)
            userDefaults.setValue(privateKey!, forKey:UIUtils.PrivateKeySettingsKey)
        }
    }

    // MARK: Internal methods

    fileprivate override init() {
        super.init()
    }

    fileprivate static func createTradingPlatform() -> TradingPlatform {
        return createBTCTradeUATradingPlatform()
    }

    fileprivate static func createBTCTradeUATradingPlatform() -> TradingPlatform {
        let result = BTCTradeUATradingPlatform()

        let userDefaults = UserDefaults.standard

        result.publicKey = userDefaults.string(forKey:UIUtils.PublicKeySettingsKey)
        result.privateKey = userDefaults.string(forKey:UIUtils.PrivateKeySettingsKey)

        return result
    }

    fileprivate static func publicKey(fromServerResponse serverResponse:[String : Any]) -> String? {
        let result = serverResponse["public-key"] as? String
        return result
    }

    fileprivate static func privateKey(fromServerResponse serverResponse:[String : Any]) -> String? {
        let result = serverResponse["private-key"] as? String
        return result
    }
}
