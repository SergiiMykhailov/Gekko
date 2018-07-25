//  Created by Sergii Mykhailov on 21/11/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation

class BTCTradeUAPostRequestFactory : NSObject {

    private override init() {

    }

    // MARK: Public methods

    public static func makePostRequest(forURL url:String,
                                       withPublicKey publicKey:String,
                                       privateKey:String,
                                       body:String = "") -> URLRequest {
        let now = Date()
        let millisecondsFrom1970 = Int64(now.timeIntervalSince1970) * 1000

        syncQueue.sync {
            nonce = nonce == nil ? millisecondsFrom1970 : nonce! + 1
        }

        let outOrderId = millisecondsFrom1970

        let request = NSMutableURLRequest(url: NSURL(string:url)! as URL)

        request.httpMethod = "POST"

        let requestBodySuffix = "out_order_id=\(outOrderId)&nonce=\(nonce!)&MerchantID=iOS_Gekko"
        let requestBody = body.isEmpty ? requestBodySuffix : String(format:"%@&%@", body, requestBodySuffix)

        request.setValue(publicKey, forHTTPHeaderField:"public-key")

        let stringForHashing = String(format:"%@%@", requestBody, privateKey)
        let hashedString = hashString(fromString:stringForHashing)

        request.setValue(hashedString, forHTTPHeaderField:"api-sign")

        request.httpBody = requestBody.data(using:.utf8)

        return request as URLRequest;
    }

    // MARK: Internal methods

    fileprivate static func hashString(fromString sourceString:String) -> String {
        var hash = [UInt8](repeating:0, count:Int(CC_SHA256_DIGEST_LENGTH))
        let sourceData = sourceString.data(using:.utf8)! as NSData
        CC_SHA256(sourceData.bytes,
                  CC_LONG(sourceData.length),
                  &hash)

        var result = ""
        for index in 0..<Int(CC_SHA256_DIGEST_LENGTH) {
            result += String(format: "%02x", hash[index])
        }

        return result
    }

    private static var nonce:Int64?
    private static let MaxOrderId:UInt32 = 1000

    private static let syncQueue = DispatchQueue(label:"com.Gekko.RequestSyncQueue")
}
