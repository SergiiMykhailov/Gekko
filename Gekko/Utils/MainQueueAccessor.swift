//  Created by Sergii Mykhailov on 05/04/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class MainQueueAccessor<ElementType> : NSObject {

    init(element:ElementType) {
        self.element = element
    }

    // MARK: Public methods and properties

    public func accessInMainQueueMutable(withBlock block:@escaping (inout ElementType) -> Void,
                                         completion:@escaping CompletionBlock) {
        if Thread.isMainThread {
            block(&element)
            completion()
        }
        else {
            DispatchQueue.main.async { [weak self] in
                if self != nil {
                    block(&self!.element)
                    completion()
                }
            }
        }
    }

    public func accessInMainQueueReadonly(withBlock block:@escaping (ElementType) -> Void) {
        if Thread.isMainThread {
            block(element)
        }
        else {
            DispatchQueue.main.async { [weak self] in
                if self != nil {
                    block(self!.element)
                }
            }
        }
    }

    // MARK: Internal fields

    fileprivate var element:ElementType
}
