//
//  UIColor+Helpers.swift
//  Pods
//
//  Created by Alex Popov on 2016-06-07.
//
//

import UIKit

internal extension UIColor {
    /**
     Initializes UIColor object from a hex-string.

     If an invalid hex-string is specified, .blackColor() is returned.

     - parameter rgba: octothorpe ('#') prefixed, valid hexadecimal string with either 3, 4, 6 or 8 digits.
     - returns: the represented color, or black on an invalid input.
     */
    convenience init(rgba: String) {
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = 1.0

        guard rgba.hasPrefix("#") else {
            print("Invalid RGB string, missing '#' as prefix")
            self.init(red:red, green:green, blue:blue, alpha:alpha)
            return
        }
        let index   = rgba.startIndex.advancedBy(1)
        let hex     = rgba.substringFromIndex(index)
        let scanner = NSScanner(string: hex)
        var hexValue: CUnsignedLongLong = 0
        guard scanner.scanHexLongLong(&hexValue) else {
            print("Scan hex error")
            self.init(red:red, green:green, blue:blue, alpha:alpha)
            return
        }
        switch hex.characters.count {
        case 3:
            red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
            green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
            blue  = CGFloat(hexValue & 0x00F)              / 15.0
        case 4:
            red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
            green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
            blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
            alpha = CGFloat(hexValue & 0x000F)             / 15.0
        case 6:
            red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
            green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
            blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
        case 8:
            red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
            green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
            blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
            alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
        default:
            print("Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8", terminator: "")
        }
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }

    /**
     Hex string of a UIColor instance.

     - parameter rgba: Whether the alpha should be included.
     */
    // from: https://github.com/yeahdongcn/UIColor-Hex-Swift
    func hexString(includeAlpha: Bool) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)

        if (includeAlpha) {
            return String(format: "#%02X%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
        } else {
            return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        }
    }

    // MARK: - color shades
    // https://gist.github.com/mbigatti/c6be210a6bbc0ff25972

    func highlightColor() -> UIColor {

        var hue : CGFloat = 0
        var saturation : CGFloat = 0
        var brightness : CGFloat = 0
        var alpha : CGFloat = 0

        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return UIColor(hue: hue, saturation: 0.30, brightness: 1, alpha: alpha)
        } else {
            return self;
        }

    }

    /**
     Returns a lighter color by the provided percentage

     :param: lighting percent percentage
     :returns: lighter UIColor
     */
    func lighterColor(percent : Double) -> UIColor {
        return colorWithBrightnessFactor(CGFloat(1 + percent));
    }

    /**
     Returns a darker color by the provided percentage

     :param: darking percent percentage
     :returns: darker UIColor
     */
    func darkerColor(percent : Double) -> UIColor {
        return colorWithBrightnessFactor(CGFloat(1 - percent));
    }

    /**
     Return a modified color using the brightness factor provided

     :param: factor brightness factor
     :returns: modified color
     */
    func colorWithBrightnessFactor(factor: CGFloat) -> UIColor {
        var hue : CGFloat = 0
        var saturation : CGFloat = 0
        var brightness : CGFloat = 0
        var alpha : CGFloat = 0

        if getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return UIColor(hue: hue, saturation: saturation, brightness: brightness * factor, alpha: alpha)
        } else {
            return self;
        }
    }
}