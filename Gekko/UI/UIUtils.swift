//  Created by Sergii Mykhailov on 02/01/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class UIUtils {

    //MARK: Methods
    
    public static func blink(aboveView view:UIView) {
        let blinkingView = UIView()
        blinkingView.backgroundColor = UIColor.white
        blinkingView.alpha = 0

        view.addSubview(blinkingView)

        blinkingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        UIView.animate(withDuration:UIDefaults.DefaultAnimationDuration,
                       animations: {
                        blinkingView.alpha = 0.75
        }) { (_) in
            UIView.animate(withDuration:UIDefaults.DefaultAnimationDuration,
                           animations: {
                            blinkingView.alpha = 0
            }, completion: { (_) in
                blinkingView.removeFromSuperview()
            })
        }
    }
    
    // MARK: Properties
    
    public static let PublicKeySettingsKey = "Public Key"
    public static let PrivateKeySettingsKey = "Private Key"
    public static let UserNameSettingsKey = "User Name"
    public static let SecurityKeySettingsKey = "Security Key"
    public static let UserIDSettingsKey = "User ID"
    public static let UserPasswordSettingsKey = "User Password"
}
