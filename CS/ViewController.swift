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

class ViewController: NSViewController {

    @IBOutlet weak var theButton: NSButton! { didSet { } }
    @IBOutlet weak var theTable: NSTableView! {
        didSet {
            theTable?.setDataSource(self)
            theTable?.setDelegate(self)
        }
    }

    var xmlDoc: AEXMLDocument = AEXMLDocument()
    var haystack: [AEXMLElement] = []

    let MyRowType = "MyRowType"

    override func viewDidLoad() {
        super.viewDidLoad()

        load()
        theTable.registerForDraggedTypes([MyRowType, NSFilenamesPboardType])


    }

    // ------------------------------------------------------------------------------
    func load() {

        guard let
            xmlPath = NSBundle.mainBundle().pathForResource("GlobalClone00001", ofType: "TLL"),
            data = NSData(contentsOfFile: xmlPath)
            else { return }

        do {
            xmlDoc = try AEXMLDocument(xmlData: data)

            // i know that my channels are on DTV (digital tv)
            for item in xmlDoc.root["CHANNEL"]["DTV"].children {
                if item["serviceType"].stringValue != "2" {
                    haystack.append(item)
                    item.removeFromParent()
                }
            }

            print("Length: \(haystack.count)")

            // remove the old DTV node
            //xmlDoc.root["CHANNEL"]["DTV"].removeFromParent()
        }
        catch {
            print("\(error)")
        }
    }


    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // ------------------------------------------------------------------------------
    func hexStringtoAscii(hexString : String) -> String {
        let pattern = "(0x)?([0-9a-f]{2})"
        let regex = try! NSRegularExpression(pattern: pattern, options: .CaseInsensitive)
        let nsString = hexString as NSString
        let matches = regex.matchesInString(hexString, options: [], range: NSMakeRange(0, nsString.length))
        let characters = matches.map {
            Character(UnicodeScalar(UInt32(nsString.substringWithRange($0.rangeAtIndex(2)), radix: 16)!))
        }
        return String(characters)
    }





}

extension ViewController : NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return haystack.count ?? 0
    }

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

    func tableView(tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        theTable.setDropRow(row, dropOperation: NSTableViewDropOperation.Above)
        return NSDragOperation.Move
    }

    func tableView(tableView: NSTableView, writeRowsWithIndexes rowIndexes: NSIndexSet, toPasteboard pboard: NSPasteboard) -> Bool {
        let data = NSKeyedArchiver.archivedDataWithRootObject([rowIndexes])
        pboard.declareTypes([MyRowType], owner:self)
        pboard.setData(data, forType:MyRowType)

        return true
    }

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



}

extension ViewController : NSTableViewDelegate {
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {

        var text:String = ""
        var cellIdentifier: String = ""

        // 1


        guard let item:AEXMLElement = haystack[row] else {
            return nil
        }

        print(item)

        // 2
        if tableColumn == tableView.tableColumns[0] {

            text = item["prNum"].stringValue
            cellIdentifier = "PosCellID"
        } else if tableColumn == tableView.tableColumns[1] {
            text = hexStringtoAscii(item["hexVchName"].stringValue)
            cellIdentifier = "NameCellID"
        }

        // 3
        if let cell = tableView.makeViewWithIdentifier(cellIdentifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }

}


