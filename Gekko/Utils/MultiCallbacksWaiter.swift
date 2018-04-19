//  Created by Sergii Mykhailov on 03/04/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

typealias CompletionBlock = () -> Void

class MultiCallbacksWaiter : NSObject {

    init(withNumberOfInvokations invokationsCount:UInt32,
         onCompletion:@escaping CompletionBlock) {

        self.requiredInvokationsCount = invokationsCount
        self.completionBlock = onCompletion
    }

    public func handleCompletion() -> Void {
        currentInvokationsCount += 1

        if currentInvokationsCount >= requiredInvokationsCount {
            completionBlock()
        }
    }

    // MARK: Internal fields

    fileprivate var requiredInvokationsCount:UInt32
    fileprivate var currentInvokationsCount:UInt32 = 0
    fileprivate var completionBlock:CompletionBlock
}
