//
//  WindowController.swift
//  CS
//
//  Created by Martin Kautz on 15.04.16.
//  Copyright © 2016 Raketenmann. All rights reserved.
//

import Cocoa
import AEXML

class WindowController: NSWindowController {

    //var xmlDoc: AEXMLDocument = AEXMLDocument()
    //var haystack: [AEXMLElement] = []

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }


    // ---------------------------------------------------------------------------------------------
    // MARK: - User triggered actions
    // ---------------------------------------------------------------------------------------------
    @IBAction func openTLLFile(sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["TLL"]

        openPanel.beginWithCompletionHandler { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                self._load(openPanel.URL!)
            }
        }
    }

    @IBAction func saveXmlFile(sender: AnyObject) {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "GlobalClone00001"
        savePanel.allowedFileTypes = ["TLL"]
        savePanel.showsHiddenFiles = true
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.beginWithCompletionHandler { (result) in
            if result == NSFileHandlingPanelOKButton {
                let exportedFileURL = savePanel.URL
                self._save(exportedFileURL!)
            }
        }
    }


    // ---------------------------------------------------------------------------------------------
    // MARK: Load & save XML
    // ---------------------------------------------------------------------------------------------
    func _load(url: NSURL) {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT

        var haystack: [AEXMLElement] = []

        dispatch_async(dispatch_get_global_queue(priority, 0)) {

            guard let
                data = NSData(contentsOfURL: url)
                else { return }

            do {
                let xmlDoc = try AEXMLDocument(xmlData: data)

                // i know that my channels are on DTV (digital tv)
                for item in xmlDoc.root["CHANNEL"]["DTV"].children {
                    if item["serviceType"].stringValue != "2" { // no interested in Radio
                        haystack.append(item)
                        item.removeFromParent()
                    }
                }

                dispatch_async(dispatch_get_main_queue()) {
                    print("Length: \(haystack.count)")
                    SimpleDAO.sharedInstance.xmlDoc = xmlDoc
                    SimpleDAO.sharedInstance.haystack = haystack

                    //self.theTable.reloadData()
                    //self.theCurrentUrl = url
                    // send notification
                    /*
                    let userInfo = [
                        "haystack" : self.haystack
                    ]
                    */
                    NSNotificationCenter.defaultCenter().postNotificationName("DidGetData", object: nil, userInfo: nil);

                }
            }
            catch {
                print("\(error)")
            }
            
        }
    }

    func _save(url: NSURL) {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {

            for (index, _) in SimpleDAO.sharedInstance.haystack.enumerate() {
                SimpleDAO.sharedInstance.xmlDoc.root["CHANNEL"]["DTV"].addChild(SimpleDAO.sharedInstance.haystack[index])
            }

            do {
                // LG TV is somewhat picky when it comes to XML
                // no indentation, line endings with CRLF
                let sXML = SimpleDAO.sharedInstance.xmlDoc.xmlString
                    .stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    .stringByReplacingOccurrencesOfString("\n", withString: "\r\n")
                    .stringByReplacingOccurrencesOfString("\t", withString: "")
                try sXML.writeToURL(url as NSURL, atomically: true, encoding: NSUTF8StringEncoding)
            } catch {
                // add some error handling here
            }
            dispatch_async(dispatch_get_main_queue()) {
                
            }
        }
    }



}
