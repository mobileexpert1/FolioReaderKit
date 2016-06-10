//
//  AddNote.swift
//  Pods
//
//  Created by pankaj_mac_mini on 09/06/16.
//
//

import UIKit
@objc protocol AddNoteDelegate: class {
    func noteSaved(noteText: String)
}
class AddNote: UIViewController {
   weak var delegate: AddNoteDelegate!
    var webView: UIWebView!
     var highlightString: String!
     var noteText: String!
    @IBOutlet weak var noteTxtView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        noteTxtView.becomeFirstResponder()
        // Do any additional setup after loading the view.
        noteTxtView.text = noteText
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelNote(sender: AnyObject) {
        if noteText == nil {
         webView.removeHighlightOnNoteCancel()
        }
      self.dismissViewControllerAnimated(true, completion: {});
        
    }
    @IBAction func saveNote(sender: AnyObject) {
        
        if (noteTxtView.text.characters.count==0) {
           
            let alertController = UIAlertController(title: "GoshenWells", message:
                "Note is empty.", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default,handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
            return;
        
        }
        currentNote = noteTxtView.text
        webView.highlightAndSaveNote(highlightString)
        self.dismissViewControllerAnimated(true, completion: {});
        // delegate.noteSaved(noteTxtView.text)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
