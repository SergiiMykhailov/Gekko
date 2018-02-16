//  Created by Sergii Mykhailov on 21/11/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation

class BTCTradeUAPostRequestFactory : NSObject {

    private override init() {

    }

    static func makePostRequest(forURL url:String,
                                withPublicKey publicKey:String,
                                privateKey:String,
                                body:String = "") -> URLRequest {
        syncQueue.sync {
            nonceCount += 1
        }

        let millisecondsFrom1970 = Int(Date.timeIntervalBetween1970AndReferenceDate) * 1000
        let outOrderId = millisecondsFrom1970

        let request = NSMutableURLRequest(url: NSURL(string:url)! as URL)

        request.httpMethod = "POST"

        let requestBodySuffix = String(format:"out_order_id=%d&nonce=%d", outOrderId, nonceCount)
        let requestBody = body.isEmpty ? requestBodySuffix : String(format:"%@&%@", body, requestBodySuffix)

        request.setValue(publicKey, forHTTPHeaderField:"public-key")

        let stringForHashing = String(format:"%@%@", requestBody, privateKey)
        let hashedString = hashString(fromString:stringForHashing)

        request.setValue(hashedString, forHTTPHeaderField:"api-sign")

        request.httpBody = requestBody.data(using:.utf8)

        return request as URLRequest;
    }

    private static func hashString(fromString sourceString:String) -> String {
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

    private static var nonceCount = 0
    private static let MaxOrderId:UInt32 = 1000

    private static let syncQueue = DispatchQueue(label:"com.Gekko.RequestSyncQueue")
}
