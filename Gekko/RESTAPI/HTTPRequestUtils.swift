//  Created by Sergii Mykhailov on 14/07/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class HTTPRequestUtils : NSObject {

    fileprivate override init() {

    }

    // MARK: Public methods and properties

    public static func makePostRequestBody(fromDictionary dictionary:[String : String]) -> String {
        var result = ""

        var index = 0
        for (key, value) in dictionary {
            var currentPairString = ""

            if index != 0 {
                currentPairString += "&"
            }

            currentPairString += "\(key)=\(value)"
            result += currentPairString

            index += 1
        }

        return result
    }
}
