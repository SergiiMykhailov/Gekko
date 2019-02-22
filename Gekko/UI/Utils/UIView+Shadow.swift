//
//  UIView+Shadow.swift
//  DimDim
//
//  Created by Sergii Mykhailov on 12/12/2018.
//  Copyright © 2018 Vigo Group. All rights reserved.
//

import Foundation
import UIKit

public let DefaultShadowOpacity:Float = 0.07
public let DefaultShadowOffset = CGSize(width:5, height:5)
public let DefaultShadowRadius:CGFloat = 4

extension UIView {
    
    func applyFullShadow(withOpacity opacity:Float? = nil) {
        applyShadow(opacity:opacity ?? DefaultShadowOpacity,
                    offset:DefaultShadowOffset,
                    radius:DefaultShadowRadius)
    }
    
    func applyBottomShadow(withOpacity opacity:Float? = nil) {
        applyShadow(opacity:opacity ?? DefaultShadowOpacity,
                    offset:CGSize(width: 0, height: 4),
                    radius:layer.cornerRadius)
    }
    
    func applyShadow(color:UIColor = .black,
                     opacity:Float = DefaultShadowOpacity,
                     offset:CGSize = DefaultShadowOffset,
                     radius:CGFloat = DefaultShadowRadius,
                     maskToBounds:Bool = false) {
        let shadowBounds = CGRect(x:0,
                                  y:0,
                                  width:bounds.width + offset.width,
                                  height:bounds.height + offset.height)
        
        layer.shadowColor = color.cgColor
        layer.shadowPath = UIBezierPath(rect:shadowBounds).cgPath
        layer.rasterizationScale = UIScreen.main.scale
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
    }
}
