//  Created by Sergii Mykhailov on 13/07/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class BTCTradeUAAccountRegistrator : BTCTradeUAProviderBase {

    // MARK: Public methods and properties

    func registerAccount(withEmail email:String,
                         phoneNumber:String,
                         password:String,
                         onCompletion:@escaping AccountRegistrationCompletionCallback) {
        let body = HTTPRequestUtils.makePostRequestBody(fromDictionary:
            [BTCTradeUAAccountRegistrator.EmailKey : email,
             BTCTradeUAAccountRegistrator.PhoneKey : phoneNumber,
             BTCTradeUAAccountRegistrator.PasswordKey : password])

        super.performUserRequestAsync(withSuffix:BTCTradeUAAccountRegistrator.RegistrationSuffix,
                                      publicKey:BTCTradeUAAccountRegistrator.RegistrationPublicKey,
                                      privateKey:BTCTradeUAAccountRegistrator.RegistrationPrivateKey,
                                      body:body,
                                      prefixUrl:BTCTradeUAAccountRegistrator.RegistrationPrefix)
        { [weak self] (items, error) in
            let result = self?.registrationResult(fromItems:items)

            onCompletion(result, items)
        }
    }

    public static func publicKey(fromItems items:[String : Any]) -> String? {
        return items[BTCTradeUAAccountRegistrator.PublicKeyResponseKey] as? String
    }

    public static func privateKey(fromItems items:[String : Any]) -> String? {
        return items[BTCTradeUAAccountRegistrator.PrivateKeyResponseKey] as? String
    }

    public static func securityKey(fromItems items:[String : Any]) -> String? {
        return items[BTCTradeUAAccountRegistrator.SecurityKeyResponseKey] as? String
    }

    // MARK: Internal methods

    fileprivate func registrationResult(fromItems items:[String : Any]) -> AccountRegistrationStatus? {
        let publicKey = BTCTradeUAAccountRegistrator.publicKey(fromItems:items)
        let privateKey = BTCTradeUAAccountRegistrator.privateKey(fromItems:items)
        let username = items[BTCTradeUAAccountRegistrator.UserNameResponseKey] as? String
        let securityKey = BTCTradeUAAccountRegistrator.securityKey(fromItems:items)

        if publicKey != nil && privateKey != nil && username != nil && securityKey != nil {
            return AccountRegistrationStatus.Succeeded
        }

        return AccountRegistrationStatus.UnknownError
    }

    // MARK: Internal fields

    fileprivate static let RegistrationSuffix = "try_regis"

    fileprivate static let EmailKey = "email"
    fileprivate static let PasswordKey = "password"
    fileprivate static let PhoneKey = "phone"

    fileprivate static let PublicKeyResponseKey = "public_key"
    fileprivate static let PrivateKeyResponseKey = "private_key"
    fileprivate static let UserNameResponseKey = "username"
    fileprivate static let SecurityKeyResponseKey = "private_key_2fa"

    // ATTENTION: These keys should be specified manually before release
#if DEBUG
    fileprivate static let RegistrationPublicKey = ""
    fileprivate static let RegistrationPrivateKey = ""
    fileprivate static let RegistrationPrefix = "http://hidden.btc-trade.com.ua:8013/api/"
#endif
}
