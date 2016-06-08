//
//  FolioReaderContainer.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 15/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import FontBlaster

var readerConfig: FolioReaderConfig!
var epubPath: String?
var book: FRBook!

enum SlideOutState {
    case BothCollapsed
    case LeftPanelExpanded
    case Expanding
    
    init () {
        self = .BothCollapsed
    }
}

/**
 Protocol that informs the delegate of activity in the Side Panel, such as open, close, and row selected in menu.
 */
protocol FolioReaderContainerDelegate: class {
    /**
    Notifies that the menu was expanded.
    */
    func container(didExpandLeftPanel sidePanel: FolioReaderSidePanel)
    
    /**
    Notifies that the menu was closed.
    */
    func container(didCollapseLeftPanel sidePanel: FolioReaderSidePanel)
    
    /**
    Notifies when the user selected some item on menu.
    */
    func container(sidePanel: FolioReaderSidePanel, didSelectRowAtIndexPath indexPath: NSIndexPath, withTocReference reference: FRTocReference)
}

/**
 Top-level ViewController that encompasses the entire reader.
*/
public class FolioReaderContainer: UIViewController, FolioReaderSidePanelDelegate {
    weak var delegate: FolioReaderContainerDelegate!
    var centerNavigationController: UINavigationController!
    var centerViewController: FolioReaderCenter!
    var leftViewController: FolioReaderSidePanel!
    var audioPlayer: FolioReaderAudioPlayer!
    var centerPanelExpandedOffset: CGFloat = 70
    var currentState = SlideOutState()
    var shouldHideStatusBar = true
    private var errorOnLoad = false
    private var shouldRemoveEpub = true
    
    // MARK: - Init
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }


    init(config configOrNil: FolioReaderConfig!, epubPath epubPathOrNil: String? = nil, removeEpub: Bool) {
        readerConfig = configOrNil
        epubPath = epubPathOrNil
        shouldRemoveEpub = removeEpub
        super.init(nibName: nil, bundle: NSBundle.frameworkBundle())
        
        // Init with empty book
        book = FRBook()
        
        // Register custom fonts
        FontBlaster.blast(NSBundle.frameworkBundle())
        
        // Register initial defaults
        FolioReader.defaults.registerDefaults([
            kCurrentFontFamily: 0,
            kNightMode: false,
            kCurrentFontSize: 2,
            kCurrentAudioRate: 1,
            kCurrentHighlightStyle: 0,
            kCurrentMediaOverlayStyle: MediaOverlayStyle.Default.rawValue
        ])
    }
    
    // MARK: - View life cicle
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        createCenterViewController()
        createCenterNavigationController()

        // Add gestures
        createTapGestureRecognizer()
        createPanGestureRecognizer()
        // Read async book
        let priority = DISPATCH_QUEUE_PRIORITY_HIGH
        dispatch_async(dispatch_get_global_queue(priority, 0), tryLoadingEbook)
    }

    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        showShadowForCenterViewController(true)
        // @TODO: can we actually guarantee that `errorOnLoad` will be set before `viewDidAppear(_:)` is called?
        if errorOnLoad {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }

    // MARK: UI Creation

    /**
     Initializes a `FolioReaderCenter`, sets itself as the container, and sets it on the `FolioReader` singleton.
    */
    private func createCenterViewController() {
        centerViewController = setupCenterViewController()
        centerViewController.folioReaderContainer = self
        FolioReader.sharedInstance.readerCenter = centerViewController
    }

    /**
     Customization point for the `FolioReaderCenter`. 
     
     Override this method to inject your subclass of `FolioReaderCenter` into the Reader.
     
     - seealso: `FolioReaderCenter`
    */
    public func setupCenterViewController() -> FolioReaderCenter {
        return FolioReaderCenter()
    }

    /**
     Initializes the `centerNavigationController` with `centerViewController` as the root view controller, adds it to the view hierarchy, 
     and configures the navigation bar.
     
     - precondition: `centerViewController` has already been set.
    */
    private func createCenterNavigationController() {
        centerNavigationController = UINavigationController(rootViewController: centerViewController)
        centerNavigationController.setNavigationBarHidden(readerConfig.shouldHideNavigationOnTap, animated: false)
        view.addSubview(centerNavigationController.view)
        addChildViewController(centerNavigationController)
        centerNavigationController.didMoveToParentViewController(self)
    }

    /**
     Creates Tap Recognizer in the center view, responsible for showing and hiding the navigation bar, if `shouldHideNavigationOnTap` is `true`.
     
     We add our own actions here so that clients can't break FolioReader by not calling `super`
    */
    private func createTapGestureRecognizer() {
        let tapGestureRecognizer = setupTapGestureRecognizer()
        tapGestureRecognizer.addTarget(self, action: #selector(FolioReaderContainer.handleTapGesture(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        centerNavigationController.view.addGestureRecognizer(tapGestureRecognizer)
    }

    /**
     Customization point for the Tap Recognizer in the center view.
     
     Override this method if you want to add your own actions to the tap gesture recognizer.
    */
    public func setupTapGestureRecognizer() -> UITapGestureRecognizer {
        return UITapGestureRecognizer()
    }

    /**
     Creates the Pan Recognizer in the center view, responsible for showing and hiding the side menu.
     
     We add our own actions here so that clients can't break FolioReader by not calling `super`
    */
    private func createPanGestureRecognizer() {
        let panGestureRecognizer = setupPanGestureRecognizer()
        panGestureRecognizer.addTarget(self, action: #selector(FolioReaderContainer.handlePanGesture(_:)))
        centerNavigationController.view.addGestureRecognizer(panGestureRecognizer)
    }

    /**
     Customization point for the Pan Recognizer in the center view. 
     
     Override this ethod if you want to add your own actions to the pan gesture recognizer.
    */
    public func setupPanGestureRecognizer() -> UIPanGestureRecognizer {
        return UIPanGestureRecognizer()
    }

    // MARK: Ebook Loading

    /**
     Attempts to open the passed-in `epubPath`
     
     If the `epubPath` is nil, the `errorOnLoad` flag will be set, and the view controller will be dismissed once it's finished loading.
    */
    private func tryLoadingEbook() {
        guard let epubPath = epubPath else {
            print("Epub path is nil.")
            errorOnLoad = true
            return
        }

        var isDir: ObjCBool = false
        let fileManager = NSFileManager.defaultManager()

        if fileManager.fileExistsAtPath(epubPath, isDirectory:&isDir) {
            if isDir {
                book = FREpubParser().readEpub(filePath: epubPath)
            } else {
                book = FREpubParser().readEpub(epubPath: epubPath, removeEpub: self.shouldRemoveEpub)
            }
        }
        else {
            print("Epub file does not exist.")
            self.errorOnLoad = true
        }

        FolioReader.sharedInstance.isReaderOpen = true

        guard self.errorOnLoad == false else {
            return
        }
        // Reload data
        dispatch_async(dispatch_get_main_queue(), ebookDidLoad)
    }

    /**
     Reloads the `centerViewController` and adds the remaining UI.
     
     - precondition: Ebook has been successfully loaded.
    */
    private func ebookDidLoad() {
        self.centerViewController.reloadData()
        self.addLeftPanelViewController()
        self.addAudioPlayer()

        // Open panel if does not have a saved point
        if FolioReader.defaults.valueForKey(kBookId) == nil {
            self.toggleLeftPanel()
        }

        FolioReader.sharedInstance.isReaderReady = true
    }

    // MARK: CenterViewController delegate methods

    /**
     Opens/closes the Left Panel depending on current state. 
     
     If the Left Panel is not expanded it is created.
    */
    func toggleLeftPanel() {
        let notAlreadyExpanded = (currentState != .LeftPanelExpanded)

        /* 
         FIXME: this seems a little hacky. We should either check if `leftPanelViewController` is nil here,
         or just always call `addLeftPanelViewController`, since it checks for nil. 
         This if-statement seems misleading, as if it re-create the Left Panel every single time we need it.
        */
        if notAlreadyExpanded {
            addLeftPanelViewController()
        }
        
        animateLeftPanel(shouldExpand: notAlreadyExpanded)
    }

    /**
     Closes the Left Panel if it is currently open; does nothing otherwise.
    */
    func collapseSidePanels() {
        if case .LeftPanelExpanded = currentState {
            toggleLeftPanel()
        }
    }

    /**
     Adds the Left Panel iff it has not been created yet.
    */
    func addLeftPanelViewController() {
        guard leftViewController == nil else {
            return
        }
        leftViewController = FolioReaderSidePanel()
        leftViewController.delegate = self
        addChildSidePanelController(leftViewController!)

        FolioReader.sharedInstance.readerSidePanel = leftViewController
    }

    // TODO: This only gets called once; is it really worth separating it out of an 8-line function?
    func addChildSidePanelController(sidePanelController: FolioReaderSidePanel) {
        view.insertSubview(sidePanelController.view, atIndex: 0)
        addChildViewController(sidePanelController)
        sidePanelController.didMoveToParentViewController(self)
    }
    
    func animateLeftPanel(shouldExpand shouldExpand: Bool) {
        if (shouldExpand) {
            if let width = pageWidth {
                if isPad {
                    centerPanelExpandedOffset = width-400
                } else {
                    // Always get the device width
                    let w = UIInterfaceOrientationIsPortrait(UIApplication.sharedApplication().statusBarOrientation) ? UIScreen.mainScreen().bounds.size.width : UIScreen.mainScreen().bounds.size.height
                    
                    centerPanelExpandedOffset = width-(w-70)
                }
            }
            
            currentState = .LeftPanelExpanded
            delegate.container(didExpandLeftPanel: leftViewController)
            animateCenterPanelXPosition(targetPosition: centerNavigationController.view.frame.width - centerPanelExpandedOffset)
            
            // Reload to update current reading chapter
            leftViewController.tableView.reloadData()
        } else {
            animateCenterPanelXPosition(targetPosition: 0) { finished in
                self.delegate.container(didCollapseLeftPanel: self.leftViewController)
                self.currentState = .BothCollapsed
            }
        }
    }
    
    func animateCenterPanelXPosition(targetPosition targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.centerNavigationController.view.frame.origin.x = targetPosition
            }, completion: completion)
    }

    // TODO: this is only called once, and always with `true`. Worth removing/refactoring? 
    // This could just get absorbed into `createCenterNavigationController`
    func showShadowForCenterViewController(shouldShowShadow: Bool) {
        if (shouldShowShadow) {
            centerNavigationController.view.layer.shadowOpacity = 0.2
            centerNavigationController.view.layer.shadowRadius = 6
            centerNavigationController.view.layer.shadowPath = UIBezierPath(rect: centerNavigationController.view.bounds).CGPath
            centerNavigationController.view.clipsToBounds = false
        } else {
            centerNavigationController.view.layer.shadowOpacity = 0
            centerNavigationController.view.layer.shadowRadius = 0
        }
    }
    
    func addAudioPlayer(){
        // @NOTE: should the audio player only be initialized if the epub has audio smil?
        audioPlayer = FolioReaderAudioPlayer()

        FolioReader.sharedInstance.readerAudioPlayer = audioPlayer;
    }

    // MARK: Gesture recognizer
    
    func handleTapGesture(recognizer: UITapGestureRecognizer) {
        if case .LeftPanelExpanded = currentState {
            toggleLeftPanel()
        }
    }
    
    func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let gestureIsDraggingFromLeftToRight = (recognizer.velocityInView(view).x > 0)
        // FIXME: we force-unwrap `recognizer.view!` so much here that we might as well just guard against it and save the keystrokes/exclamation-mark stress
        switch(recognizer.state) {
        case .Began where currentState == .BothCollapsed && gestureIsDraggingFromLeftToRight:
            currentState = .Expanding
        case .Changed where currentState == .LeftPanelExpanded || currentState == .Expanding && recognizer.view!.frame.origin.x >= 0:
            recognizer.view!.center.x = recognizer.view!.center.x + recognizer.translationInView(view).x
            recognizer.setTranslation(CGPointZero, inView: view)
        case .Ended:
            guard let leftViewController = leftViewController else {
                return
            }
            let gap = 20 as CGFloat
            let xPos = recognizer.view!.frame.origin.x
            let canFinishAnimation = gestureIsDraggingFromLeftToRight && xPos > gap
            animateLeftPanel(shouldExpand: canFinishAnimation)
        default:
            break
        }
    }
    
    // MARK: - Status Bar
    
    override public func prefersStatusBarHidden() -> Bool {
        return readerConfig.shouldHideNavigationOnTap == false ? false : shouldHideStatusBar
    }
    
    override public func preferredStatusBarUpdateAnimation() -> UIStatusBarAnimation {
        return UIStatusBarAnimation.Slide
    }
    
    override public func preferredStatusBarStyle() -> UIStatusBarStyle {
        return isNight(.LightContent, .Default)
    }
    
}

// MARK: - Side Panel delegate
extension FolioReaderContainer {

    func sidePanel(sidePanel: FolioReaderSidePanel, didSelectRowAtIndexPath indexPath: NSIndexPath, withTocReference reference: FRTocReference) {
        collapseSidePanels()
        delegate.container(sidePanel, didSelectRowAtIndexPath: indexPath, withTocReference: reference)
    }

}
