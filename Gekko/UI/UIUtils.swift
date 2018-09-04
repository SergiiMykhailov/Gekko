//  Created by Sergii Mykhailov on 02/01/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LocalAuthentication

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

    public static func presentNotification(withMessage message:String,
                                           onView containerView:UIView,
                                           onCompletion:CompletionBlock) {
        let label = UILabel()
        label.text = message
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping

        let labelContainerView = UIView()
        labelContainerView.backgroundColor = UIColor(white:0, alpha:0.1)
        labelContainerView.alpha = 0
        labelContainerView.layer.cornerRadius = UIDefaults.CornerRadius

        containerView.addSubview(labelContainerView)
        labelContainerView.addSubview(label)

        labelContainerView.setContentHuggingPriority(.required, for:.vertical)
        labelContainerView.setContentHuggingPriority(.required, for:.horizontal)
        labelContainerView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.equalToSuperview().offset(UIDefaults.Spacing)
            make.right.equalToSuperview().offset(-UIDefaults.Spacing)
        }

        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(UIDefaults.Spacing)
            make.bottom.equalToSuperview().offset(-UIDefaults.Spacing)
            make.left.equalToSuperview().offset(UIDefaults.Spacing)
            make.right.equalToSuperview().offset(-UIDefaults.Spacing)
        }

        UIView.animateKeyframes(withDuration:NotificationAnimationDuration,
                                delay:0,
                                options:.calculationModeLinear,
                                animations: {
                                    UIView.addKeyframe(withRelativeStartTime:0,
                                                       relativeDuration:1.0 / 8.0,
                                                       animations: {
                                                        labelContainerView.alpha = 1
                                                        label.alpha = 1
                                    })

                                    UIView.addKeyframe(withRelativeStartTime: 1.0 / 4.0 * NotificationAnimationDuration,
                                                       relativeDuration:1.0 / 4.0,
                                                       animations: {
                                                        labelContainerView.alpha = 0
                                                        label.alpha = 0
                                    })
        }) { (_) in
            labelContainerView.removeFromSuperview()
        }
    }

    typealias AuthenticationCompletionCallback = (Bool, Error?) -> Void

    public static func authenticate(onCompletion:@escaping AuthenticationCompletionCallback) {
        let localAuthenticationContext = LAContext()
        localAuthenticationContext.localizedFallbackTitle = NSLocalizedString("Use Passcode", comment:"Fallback title")

        let reasonString = NSLocalizedString("To access the application", comment: "Authentication reason string")

        localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthentication,
                                                  localizedReason:reasonString,
                                                  reply:onCompletion)
    }

    public static func formatAssetValue(amount:Double) -> String {
        var floatingPointsCount = 0

        if amount < MinValueFor2FloatingPoints {
            floatingPointsCount = 2
        }
        if amount < MinValueFor5FloatingPoints {
            floatingPointsCount = 5
        }

        let result = String(format:"%.\(floatingPointsCount)f", amount)

        return result
    }
    
    // MARK: Properties
    
    public static let PublicKeySettingsKey = "Public Key"
    public static let PrivateKeySettingsKey = "Private Key"
    public static let UserNameSettingsKey = "User Name"
    public static let SecurityKeySettingsKey = "Security Key"
    public static let UserIDSettingsKey = "User ID"
    public static let UserPasswordSettingsKey = "User Password"

    fileprivate static let NotificationAnimationDuration:TimeInterval = 2.0
    fileprivate static let MinValueFor2FloatingPoints:Double = 10000
    fileprivate static let MinValueFor5FloatingPoints:Double = 10
}
