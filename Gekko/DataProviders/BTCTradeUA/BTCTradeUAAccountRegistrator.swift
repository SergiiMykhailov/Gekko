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
                                      body:body)
        { [weak self] (items, error) in
            let result = self?.registrationResult(fromItems:items)

            onCompletion(result, items)
        }
    }

    // MARK: Internal methods

    fileprivate func registrationResult(fromItems items:[String : Any]) -> AccountRegistrationStatus? {
        return AccountRegistrationStatus.UnknownError
    }

    // MARK: Internal fields

    fileprivate static let RegistrationSuffix = "try_regis"

    fileprivate static let EmailKey = "email"
    fileprivate static let PasswordKey = "password"
    fileprivate static let PhoneKey = "phone"

    // ATTENTION: These keys should be specified manually before release
    fileprivate static let RegistrationPublicKey = ""
    fileprivate static let RegistrationPrivateKey = ""
}
