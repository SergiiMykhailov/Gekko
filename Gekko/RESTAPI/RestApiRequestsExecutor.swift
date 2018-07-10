//  Created by Sergii Mykhailov on 19/11/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation

typealias ServiceResponse = ([String : Any], Error?) -> Void

class RestApiRequestsExecutor : NSObject {

    public static func performHTTPGetRequest(path:String, onCompletion:@escaping ServiceResponse) {
        let request = URLRequest(url: URL(string: path)!)

        performHTTPRequest(request:request, onCompletion:onCompletion)
    }

    public static func performHTTPRequest(request:URLRequest, onCompletion:@escaping ServiceResponse) {
        SerialBackgroundTasksExecutor.shared.enqueue { (completionHandler) in
            let session = URLSession.shared

            let task = session.dataTask(with:request, completionHandler:{data, response, error -> Void in
                let replyAsJSON = data != nil ?
                    try? JSONSerialization.jsonObject(with:data!, options: []) :
                nil

                let dataAsString = data != nil ? String(data:data!, encoding:.utf8) : ""
                var items:[String : Any] = ["" : dataAsString as Any]

                if replyAsJSON != nil {
                    if let replyItems = replyAsJSON! as? [String : Any] {
                        items = replyItems
                    }
                    else if let replyItems = replyAsJSON! as? [Any] {
                        items = ["" : replyItems]
                    }
                }

                onCompletion(items, error)
                completionHandler()
            })

            task.resume()
        }

    }
}
