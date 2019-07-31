//
//  Constants.swift
//  wotabag-remote
//
//  Created by Peter Rowlands on 2019/08/09.
//  Copyright © 2019 Peter Rowlands. All rights reserved.
//

import Foundation
import CoreBluetooth

let wotabagServiceUUID = CBUUID(string: "07150001-2ba7-43c7-8df6-103ff4bcbfac")
let wotabagRPCCharacteristicUUID = CBUUID(string: "07150002-2ba7-43c7-8df6-103ff4bcbfac")
let iosMTU = 185   // iOS BLE MTU
