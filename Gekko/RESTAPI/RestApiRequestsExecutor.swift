//  Created by Sergii Mykhailov on 19/11/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation

typealias ServiceResponse = ([String : Any], Error?) -> Void

class RestApiRequestsExecutor : NSObject {

    static func performHTTPGetRequest(path:String, onCompletion:@escaping ServiceResponse) {
        let request = URLRequest(url: URL(string: path)!)

        performHTTPRequest(request:request, onCompletion:onCompletion)
    }

    static func performHTTPRequest(request:URLRequest, onCompletion:@escaping ServiceResponse) {
        let session = URLSession.shared

        let task = session.dataTask(with:request, completionHandler:{data, response, error -> Void in
            let replyAsJSON = data != nil ?
                              try? JSONSerialization.jsonObject(with:data!, options: []) :
                              nil

            if replyAsJSON != nil {
                if let replyItems = replyAsJSON! as? [String : Any] {
                    onCompletion(replyItems, error)

                    return
                }

                if let replyItems = replyAsJSON! as? [Any] {
                    onCompletion(["" : replyItems], error)

                    return
                }
            }

            let dataAsString = data != nil ? String(data:data!, encoding:.utf8) : ""

            onCompletion(["" : dataAsString as Any], error)
        })
        task.resume()
    }
}
