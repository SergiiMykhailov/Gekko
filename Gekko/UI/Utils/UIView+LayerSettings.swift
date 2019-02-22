//
//  UIView+LayerSettings.swift
//  Gekko
//
//  Created by Serg Mykhailov on 22/02/2019.
//  Copyright © 2019 Sergii Mykhailov. All rights reserved.
//

import UIKit

extension UIView {
    
    @IBInspectable var cornerRadius:CGFloat {
        get { return layer.cornerRadius }
        set { layer.cornerRadius = newValue }
    }
    
    @IBInspectable var borderColor:UIColor {
        get { return UIColor(cgColor:layer.borderColor!) }
        set { layer.borderColor = newValue.cgColor }
    }
    
    @IBInspectable var borderWidth:CGFloat {
        get { return layer.borderWidth }
        set { layer.borderWidth = newValue }
    }
    
}
