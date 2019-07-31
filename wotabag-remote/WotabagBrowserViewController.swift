//
//  ViewController.swift
//  wotabag-remote
//
//  Created by Peter Rowlands on 2019/07/31.
//  Copyright © 2019 Peter Rowlands. All rights reserved.
//

import UIKit
import CoreBluetooth

class WotabagBrowserViewController: UITableViewController {
    // MARK: Properties

    var availableWotabags: [Wotabag] = []
    var centralManager: CBCentralManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100

        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableWotabags.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "WotabagBrowserTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? WotabagBrowserTableViewCell else {
            fatalError("Dequeued cell not a WotabagBrowserTableViewCell instance")
        }

        let wotabag = availableWotabags[indexPath.row]
        cell.wotabagLabel.text = wotabag.name

        return cell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
        case "ShowWotabag":
            guard let wotabagRemoteViewController = segue.destination as? WotabagRemoteViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }

            guard let selectedWotabagCell = sender as? WotabagBrowserTableViewCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }

            guard let indexPath = tableView.indexPath(for: selectedWotabagCell) else {
                fatalError("Selected cell is not in table")
            }

            let selectedWotabag = availableWotabags[indexPath.row]
            selectedWotabag.peripheral!.delegate = wotabagRemoteViewController
            if selectedWotabag.peripheral!.state == CBPeripheralState.disconnected {
                centralManager.connect(selectedWotabag.peripheral!)
            }
            wotabagRemoteViewController.wotabag = selectedWotabag
            wotabagRemoteViewController.centralManager = centralManager
        default:
            fatalError("Unexpected Segue identifier \(String(describing: segue.identifier))")
        }
    }
}

extension WotabagBrowserViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {

        case .unknown:
            print("central.state unknown")
        case .resetting:
            print("central.state resetting")
        case .unsupported:
            print("central.state unsupported")
        case .unauthorized:
            print("central.state unauthorized")
        case .poweredOff:
            print("central.state poweredOff")
        case .poweredOn:
            print("central.state poweredOn")
            centralManager.scanForPeripherals(withServices: [wotabagServiceUUID])
        @unknown default:
            print("central.state unknown")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered \(peripheral)")
        availableWotabags.append(Wotabag(peripheral: peripheral))
        self.tableView.reloadData()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral)")
        peripheral.discoverServices([wotabagServiceUUID])
    }
}

