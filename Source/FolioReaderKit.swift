//
//  FolioReaderKit.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 08/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Internal constants for devices

internal let isPad = UIDevice.currentDevice().userInterfaceIdiom == .Pad
internal let isPhone = UIDevice.currentDevice().userInterfaceIdiom == .Phone
internal let isPhone4 = (UIScreen.mainScreen().bounds.size.height == 480)
internal let isPhone5 = (UIScreen.mainScreen().bounds.size.height == 568)
internal let isPhone6P = UIDevice.currentDevice().userInterfaceIdiom == .Phone && UIScreen.mainScreen().bounds.size.height == 736
internal let isSmallPhone = isPhone4 || isPhone5
internal let isLargePhone = isPhone6P

// MARK: - Internal constants

internal let kApplicationDocumentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
internal let kCurrentFontFamily = "kCurrentFontFamily"
internal let kCurrentFontSize = "kCurrentFontSize"
internal let kCurrentAudioRate = "kCurrentAudioRate"
internal let kCurrentHighlightStyle = "kCurrentHighlightStyle"
internal var kCurrentMediaOverlayStyle = "kMediaOverlayStyle"
internal let kNightMode = "kNightMode"
internal let kHighlightRange = 30
internal var kBookId: String!

/**
 `0` Default
 `1` Underline
 `2` Text Color
 */
enum MediaOverlayStyle: Int {
    case Default
    case Underline
    case TextColor

    init () {
        self = .Default
    }

    func className() -> String {
        return "mediaOverlayStyle\(self.rawValue)"
    }
}

/**
 *  Main Library class with some useful constants and methods
 */
public class FolioReader : NSObject {
    private override init() {}

    static let sharedInstance = FolioReader()
    static let defaults = NSUserDefaults.standardUserDefaults()
    weak var readerCenter: FolioReaderCenter!
    weak var readerSidePanel: FolioReaderSidePanel!
    weak var readerContainer: FolioReaderContainer!
    weak var readerAudioPlayer: FolioReaderAudioPlayer!
    var isReaderOpen = false
    var isReaderReady = false


    var nightMode: Bool {
        get { return FolioReader.defaults.boolForKey(kNightMode) }
        set (value) {
            FolioReader.defaults.setBool(value, forKey: kNightMode)
            FolioReader.defaults.synchronize()
        }
    }
    var currentFontName: Int {
        get { return FolioReader.defaults.valueForKey(kCurrentFontFamily) as! Int }
        set (value) {
            FolioReader.defaults.setValue(value, forKey: kCurrentFontFamily)
            FolioReader.defaults.synchronize()
        }
    }

    var currentFontSize: Int {
        get { return FolioReader.defaults.valueForKey(kCurrentFontSize) as! Int }
        set (value) {
            FolioReader.defaults.setValue(value, forKey: kCurrentFontSize)
            FolioReader.defaults.synchronize()
        }
    }

    var currentAudioRate: Int {
        get { return FolioReader.defaults.valueForKey(kCurrentAudioRate) as! Int }
        set (value) {
            FolioReader.defaults.setValue(value, forKey: kCurrentAudioRate)
            FolioReader.defaults.synchronize()
        }
    }

    var currentHighlightStyle: Int {
        get { return FolioReader.defaults.valueForKey(kCurrentHighlightStyle) as! Int }
        set (value) {
            FolioReader.defaults.setValue(value, forKey: kCurrentHighlightStyle)
            FolioReader.defaults.synchronize()
        }
    }

    var currentMediaOverlayStyle: MediaOverlayStyle {
        get { return MediaOverlayStyle(rawValue: FolioReader.defaults.valueForKey(kCurrentMediaOverlayStyle) as! Int)! }
        set (value) {
            FolioReader.defaults.setValue(value.rawValue, forKey: kCurrentMediaOverlayStyle)
            FolioReader.defaults.synchronize()
        }
    }

    // MARK: - Get Cover Image

    /**
     Read Cover Image and Return an IUImage
     */
    public class func getCoverImage(epubPath: String) -> UIImage? {
        return FREpubParser().parseCoverImage(epubPath)
    }

    // MARK: - Present Folio Reader

    /**
     Present a Folio Reader for a Parent View Controller.
     */
    public class func presentReader(parentViewController parentViewController: UIViewController, withEpubPath epubPath: String, andConfig config: FolioReaderConfig, shouldRemoveEpub: Bool = true, animated: Bool = true) {
        let reader = FolioReaderContainer(config: config, epubPath: epubPath, removeEpub: shouldRemoveEpub)
        FolioReader.sharedInstance.readerContainer = reader
        parentViewController.presentViewController(reader, animated: animated, completion: nil)
    }

    // MARK: - Application State

    /**
     Called when the application will resign active
     */
    public class func applicationWillResignActive() {
        saveReaderState()
    }

    /**
     Called when the application will terminate
     */
    public class func applicationWillTerminate() {
        saveReaderState()
    }

    /**
     Save Reader state, book, page and scroll are saved
     */
    class func saveReaderState() {
        guard FolioReader.sharedInstance.isReaderOpen,
            let currentPage = FolioReader.sharedInstance.readerCenter?.currentPage else {
                return
        }
        let position = [
            "pageNumber": currentPageNumber,
            "pageOffset": currentPage.webView.scrollView.contentOffset.y
        ]

        FolioReader.defaults.setObject(position, forKey: kBookId)
        FolioReader.defaults.synchronize()
    }
}

// MARK: - Global Functions

func isNight<T> (f: T, _ l: T) -> T {
    return FolioReader.sharedInstance.nightMode ? f : l
}

// MARK: - Extensions

internal extension NSBundle {
    class func frameworkBundle() -> NSBundle {
        return NSBundle(forClass: FolioReader.self)
    }
}

internal extension UIImage {
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

extension UIViewController: UIGestureRecognizerDelegate {

    func setCloseButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(readerImageNamed: "icon-close"), style: UIBarButtonItemStyle.Plain, target: self, action:#selector(UIViewController.dismiss))
    }

    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - NavigationBar

    func setTransparentNavigation() {
        let navBar = self.navigationController?.navigationBar
        navBar?.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        navBar?.hideBottomHairline()
        navBar?.translucent = true
    }

    func setTranslucentNavigation(translucent: Bool = true, color: UIColor, tintColor: UIColor = UIColor.whiteColor(), titleColor: UIColor = UIColor.blackColor(), andFont font: UIFont = UIFont.systemFontOfSize(17)) {
        let navBar = self.navigationController?.navigationBar
        navBar?.setBackgroundImage(UIImage.imageWithColor(color), forBarMetrics: UIBarMetrics.Default)
        navBar?.showBottomHairline()
        navBar?.translucent = translucent
        navBar?.tintColor = tintColor
        navBar?.titleTextAttributes = [NSForegroundColorAttributeName: titleColor, NSFontAttributeName: font]
    }
}

internal extension UINavigationBar {

    func hideBottomHairline() {
        let navigationBarImageView = hairlineImageViewInNavigationBar(self)
        navigationBarImageView!.hidden = true
    }

    func showBottomHairline() {
        let navigationBarImageView = hairlineImageViewInNavigationBar(self)
        navigationBarImageView!.hidden = false
    }

    private func hairlineImageViewInNavigationBar(view: UIView) -> UIImageView? {
        if view.isKindOfClass(UIImageView) && view.bounds.height <= 1.0 {
            return (view as! UIImageView)
        }

        let subviews = (view.subviews )
        for subview: UIView in subviews {
            if let imageView: UIImageView = hairlineImageViewInNavigationBar(subview) {
                return imageView
            }
        }
        return nil
    }
}

internal extension Array {
    
    /**
     Return index if is safe, if not return nil
     http://stackoverflow.com/a/30593673/517707
     */
    subscript(safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}
