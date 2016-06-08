//
//  UIViewController+Helpers.swift
//  Pods
//
//  Created by Alex Popov on 2016-06-07.
//
//

import Foundation

extension UIViewController {

    /**
     Sets a close button as the `rightBarButtonItem` on a view controller.
     
     Any previously set `rightBarButtonitem`s are replaced.
    */
    func setCloseButton() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(readerImageNamed: "icon-close"), style: UIBarButtonItemStyle.Plain, target: self, action:#selector(UIViewController.dismiss))
    }

    /**
     Short-hand for `dismissViewControllerAnimated(true, completion: nil)`
    */
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - NavigationBar

    // TODO: this function is unused. Find out if we actually need it. 
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

extension UIViewController: UIGestureRecognizerDelegate {
    
}