//
//  SimpleDAO.swift
//  CS
//
//  Created by Martin Kautz on 16.04.16.
//  Copyright © 2016 Raketenmann. All rights reserved.
//

import Foundation
import AEXML

let kArrayKey = "storedDataArray"

class SimpleDAO {

    // ---------------------------------------------------------------------------------------------
    var xmlDoc: AEXMLDocument = AEXMLDocument()
    var haystack: [AEXMLElement] = []
    // ---------------------------------------------------------------------------------------------

    // ---------------------------------------------------------------------------------------------
    // ---------------------------------------------------------------------------------------------
    class var sharedInstance: SimpleDAO {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: SimpleDAO? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = SimpleDAO()
        }
        return Static.instance!
    }

    // ---------------------------------------------------------------------------------------------
    init() {
        haystack = []
    }
}
