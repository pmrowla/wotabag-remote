//
//  Wotabag.swift
//  wotabag-remote
//
//  Created by Peter Rowlands on 2019/08/09.
//  Copyright © 2019 Peter Rowlands. All rights reserved.
//

import Foundation
import CoreBluetooth

class Wotabag {

    // MARK: Properties

    var peripheral: CBPeripheral?
    var name: String?
    var status: Int

    // MARK: Initialization

    init(peripheral: CBPeripheral) {

        self.peripheral = peripheral
        let name = (peripheral.name ?? "")
        if !name.isEmpty {
            self.name = peripheral.name
        }
        else {
            self.name = "Unnamed Wotabag"
        }
        self.status = 0
    }
}
