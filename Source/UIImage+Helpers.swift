//
//  UIImage+Helpers.swift
//  Pods
//
//  Created by Alex Popov on 2016-06-07.
//
//

import UIKit

internal extension UIImage {
    /**
     Get the image most suitable for the current UITraitCollection given a file name.
    */
    convenience init?(readerImageNamed: String) {
        let traits = UITraitCollection(displayScale: UIScreen.mainScreen().scale)
        self.init(named: readerImageNamed, inBundle: NSBundle.frameworkBundle(), compatibleWithTraitCollection: traits)
    }

    func imageTintColor(tintColor: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)

        let context = UIGraphicsGetCurrentContext()! as CGContextRef
        CGContextTranslateCTM(context, 0, self.size.height)
        CGContextScaleCTM(context, 1.0, -1.0)
        CGContextSetBlendMode(context, CGBlendMode.Normal)

        let rect = CGRectMake(0, 0, self.size.width, self.size.height) as CGRect
        CGContextClipToMask(context, rect, self.CGImage)
        tintColor.setFill()
        CGContextFillRect(context, rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext() as UIImage
        UIGraphicsEndImageContext()

        return newImage
    }

    /**
     Generates a 1x1 point image of the specified color. If no color is specified `.whiteColor()` is used instead.
    */
    class func imageWithColor(color: UIColor?) -> UIImage! {
        let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let context = UIGraphicsGetCurrentContext()

        if let color = color {
            color.setFill()
        } else {
            UIColor.whiteColor().setFill()
        }

        CGContextFillRect(context, rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}

