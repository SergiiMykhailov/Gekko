//  Created by Sergii Mykhailov on 11/12/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit

class UIDefaults {

    public static let LabelDefaultFontSize:CGFloat = 15
    public static let LabelTitleFontSize:CGFloat = 14
    public static let LabelSmallFontSize:CGFloat = 13
    public static let LabelVerySmallFontSize:CGFloat = 11

    public static let LabelDefaultFontColor = UIColor.black.withAlphaComponent(0.87)
    public static let LabelDefaultLightColor = UIColor(white:142 / 255, alpha:1)

    public static let ButtonDefaultFontSize:CGFloat = 12

    public static let LineHeight:CGFloat = 44

    public static let TableCellSpacing = 15

    public static let CornerRadius:CGFloat = 8

    public static let Spacing:CGFloat = 8
    public static let SpacingSmall:CGFloat = 3

    public static let SeparatorColor = UIColor(red:239 / 255,
                                               green: 239 / 255,
                                               blue: 246 / 255,
                                               alpha: 1)

    public static let GreenColor = UIColor(red:76 / 255, green:217 / 255, blue:100 / 255, alpha:1)
    public static let RedColor = UIColor(red:1, green:45 / 255, blue:85 / 255, alpha:1)
    public static let YellowColor = UIColor(red:1, green:204 / 255, blue:0, alpha:1)
    public static let TealBlueColor = UIColor(red:90 / 255, green:200 / 255, blue:250 / 255, alpha:1)

    public static let DefaultAnimationDuration:TimeInterval = 0.25
    
    public static let TopBarOpacity:CGFloat = 0.5
    public static let TopBarFontSize:CGFloat = 24
}
