//  Created by Sergii Mykhailov on 30/03/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

protocol TradingPlatformManagerDelegate : class {

    func tradingPlatformManager(sender:TradingPlatformManager,
                                didCreateTradingPlatform tradingPlatform:TradingPlatform)

}

class TradingPlatformManager : NSObject {

    // MARK: Public methods and properties

    public static let shared = TradingPlatformManager()

    public private(set) lazy var tradingPlatform = TradingPlatformManager.createTradingPlatform()
    public weak var delegate:TradingPlatformManagerDelegate?

    public var userID:String? {
        get {
            return UserDefaults.standard.value(forKey:UIUtils.UserIDSettingsKey) as? String
        }
    }

    public var password:String? {
        get {
            return UserDefaults.standard.value(forKey:UIUtils.UserPasswordSettingsKey) as? String
        }
    }

    public var securityKey:String? {
        get {
            return UserDefaults.standard.value(forKey:UIUtils.SecurityKeySettingsKey) as? String
        }
    }

    public func handleRegistration(withUserID userID:String,
                                   password:String,
                                   serverResponse:[String : Any]) {
        let publicKey = TradingPlatformManager.publicKey(fromServerResponse:serverResponse)
        let privateKey = TradingPlatformManager.privateKey(fromServerResponse:serverResponse)
        let securityKey = TradingPlatformManager.securityKey(fromServerResponse:serverResponse)

        if publicKey != nil && privateKey != nil {
            let userDefaults = UserDefaults.standard

            userDefaults.setValue(publicKey!, forKey:UIUtils.PublicKeySettingsKey)
            userDefaults.setValue(privateKey!, forKey:UIUtils.PrivateKeySettingsKey)
            userDefaults.setValue(userID, forKey:UIUtils.UserIDSettingsKey)
            userDefaults.setValue(password, forKey:UIUtils.UserPasswordSettingsKey)
            userDefaults.setValue(securityKey, forKey:UIUtils.SecurityKeySettingsKey)
        }
    }

    // MARK: Internal methods

    fileprivate override init() {
        super.init()

        UserDefaults.standard.addObserver(self,
                                          forKeyPath:UIUtils.PrivateKeySettingsKey,
                                          options:NSKeyValueObservingOptions.new,
                                          context:nil)
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
        let result = BTCTradeUAAccountRegistrator.publicKey(fromItems:serverResponse)
        return result
    }

    fileprivate static func privateKey(fromServerResponse serverResponse:[String : Any]) -> String? {
        let result = BTCTradeUAAccountRegistrator.privateKey(fromItems:serverResponse)
        return result
    }

    fileprivate static func securityKey(fromServerResponse serverResponse:[String : Any]) -> String? {
        let result = BTCTradeUAAccountRegistrator.securityKey(fromItems:serverResponse)
        return result
    }

    // MARK: KVO

    override func observeValue(forKeyPath keyPath:String?,
                               of object:Any?,
                               change:[NSKeyValueChangeKey : Any]?,
                               context:UnsafeMutableRawPointer?) {
        if keyPath == UIUtils.PrivateKeySettingsKey {
            tradingPlatform = TradingPlatformManager.createTradingPlatform()
            delegate?.tradingPlatformManager(sender:self, didCreateTradingPlatform:tradingPlatform)
        }
    }
}
