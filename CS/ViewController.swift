//
//  ViewController.swift
//  CS
//
//  Created by Martin Kautz on 08.04.16.
//  Copyright © 2016 Raketenmann. All rights reserved.
//

import Cocoa
import AEXML
/*
 serviceType
 SDTV = 1,
	Radio = 2,
	Data = 12,
	SDTV_MPEG4 = 22,
	HDTV = 25,
	Option = 211
 */

class ViewController: NSViewController, NSWindowDelegate {

    @IBOutlet weak var theButton: NSButton!
    @IBOutlet weak var theTable: NSTableView! {
        didSet {
            theTable?.setDataSource(self)
            theTable?.setDelegate(self)
        }
    }

    var xmlDoc: AEXMLDocument = AEXMLDocument()
    var haystack: [AEXMLElement] = []

    let MyRowType = "MyRowType"

    // ---------------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        theTable.registerForDraggedTypes([MyRowType, NSFilenamesPboardType])
    }

    // ---------------------------------------------------------------------------------------------
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.delegate = self
    }

    // ---------------------------------------------------------------------------------------------
    func _saveXml(url: NSURL) {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {

            for (index, _) in self.haystack.enumerate() {
                self.xmlDoc.root["CHANNEL"]["DTV"].addChild(self.haystack[index])
            }

            do {
                try self.xmlDoc.xmlString.writeToURL(url as NSURL,
                                                     atomically: true,
                                                     encoding: NSUTF8StringEncoding)
            } catch {
                // add some error handling here
            }
            dispatch_async(dispatch_get_main_queue()) {

            }

        }
    }

    // ---------------------------------------------------------------------------------------------
    func _load(url: NSURL) {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {

            self.haystack.removeAll()

            guard let
                data = NSData(contentsOfURL: url)
                else { return }

            do {
                self.xmlDoc = try AEXMLDocument(xmlData: data)
                // i know that my channels are on DTV (digital tv)
                for item in self.xmlDoc.root["CHANNEL"]["DTV"].children {
                    if item["serviceType"].stringValue != "2" {
                        self.haystack.append(item)
                        item.removeFromParent()
                    }
                }
                dispatch_async(dispatch_get_main_queue()) {
                    print("Length: \(self.haystack.count)")
                    self.theTable.reloadData()
                }
            }
            catch {
                print("\(error)")
            }

        }
    }

    // ---------------------------------------------------------------------------------------------
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    // ---------------------------------------------------------------------------------------------
    func _hexStringtoAscii(hexString : String) -> String {
        let pattern = "(0x)?([0-9a-f]{2})"
        let regex = try! NSRegularExpression(pattern: pattern, options: .CaseInsensitive)
        let nsString = hexString as NSString
        let matches = regex.matchesInString(hexString, options: [],
                                            range: NSMakeRange(0,
                                                nsString.length))
        let characters = matches.map {
            Character(UnicodeScalar(
                UInt32(nsString.substringWithRange($0.rangeAtIndex(2)), radix: 16)!)
            )
        }
        return String(characters)
    }

    // ---------------------------------------------------------------------------------------------
    func _moveItem(item: AEXMLElement, from: Int, to: Int) {
        haystack.removeAtIndex(from)
        if(to > haystack.endIndex) {
            haystack.append(item)
        }
        else {
            haystack.insert(item, atIndex: to)
        }
        theTable.reloadData()
    }

    // ---------------------------------------------------------------------------------------------
    @IBAction func openXmlFile(sender: AnyObject) {
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

    // ---------------------------------------------------------------------------------------------
    @IBAction func saveXmlFile(sender: AnyObject) {
        let savePanel = NSSavePanel()
        savePanel.beginWithCompletionHandler { (result) in
            if result == NSFileHandlingPanelOKButton {
                let exportedFileURL = savePanel.URL
                self._saveXml(exportedFileURL!)
            }
        }
    }

    // ---------------------------------------------------------------------------------------------
    @IBAction func newOrder(sender: AnyObject) {
        for (index, _) in haystack.enumerate() {
            // get elem
            let elem = haystack[index]
            // remove old attrs
            elem["prNum"].removeFromParent()
            elem["isUserSelCHNo"].removeFromParent()
            // make new attrs
            elem.addChild(AEXMLElement("prNum", value: "\(index + 1)"))
            elem.addChild(AEXMLElement("isUserSelCHNo", value: "1"))
            theTable.reloadData()
        }
    }

    // ---------------------------------------------------------------------------------------------
    func windowShouldClose(sender: AnyObject) -> Bool {
        return false
    }

}

// -------------------------------------------------------------------------------------------------
// NSTAbleViewDatasource protocol methods
// -------------------------------------------------------------------------------------------------
extension ViewController : NSTableViewDataSource {

    // ---------------------------------------------------------------------------------------------
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return haystack.count ?? 0
    }

    // ---------------------------------------------------------------------------------------------
    func tableView(tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        let pasteboard = info.draggingPasteboard()
        let rowData = pasteboard.dataForType(MyRowType)

        if(rowData != nil) {
            var dataArray = NSKeyedUnarchiver.unarchiveObjectWithData(rowData!) as! Array<NSIndexSet>,
            indexSet = dataArray[0]

            let movingFromIndex = indexSet.firstIndex
            let item = haystack[movingFromIndex]

            _moveItem(item, from: movingFromIndex, to: row)

            return true
        }
        else {
            return false
        }
    }

    // ---------------------------------------------------------------------------------------------
    func tableView(tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        theTable.setDropRow(row, dropOperation: NSTableViewDropOperation.Above)
        return NSDragOperation.Move
    }

    // ---------------------------------------------------------------------------------------------
    func tableView(tableView: NSTableView, writeRowsWithIndexes rowIndexes: NSIndexSet, toPasteboard pboard: NSPasteboard) -> Bool {
        let data = NSKeyedArchiver.archivedDataWithRootObject([rowIndexes])
        pboard.declareTypes([MyRowType], owner:self)
        pboard.setData(data, forType:MyRowType)
        return true
    }

}

// -------------------------------------------------------------------------------------------------
// NSTAbleViewDelegate protocol methods
// -------------------------------------------------------------------------------------------------
extension ViewController : NSTableViewDelegate {
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {

        var text:String = ""
        var cellIdentifier: String = ""

        guard let item:AEXMLElement = haystack[row] else {
            return nil
        }

        if tableColumn == tableView.tableColumns[0] {
            text = item["prNum"].stringValue
            cellIdentifier = "PosCellID"
        } else if tableColumn == tableView.tableColumns[1] {
            text = _hexStringtoAscii(item["hexVchName"].stringValue)
            cellIdentifier = "NameCellID"
        }
        
        if let cell = tableView.makeViewWithIdentifier(cellIdentifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }

        return nil
    }
    
}


