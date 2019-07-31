//
//  WotabagRemoteViewController.swift
//  wotabag-remote
//
//  Created by Peter Rowlands on 2019/08/09.
//  Copyright © 2019 Peter Rowlands. All rights reserved.
//

import UIKit
import CoreBluetooth
import JSONRPCKit

class WotabagRemoteViewController: UIViewController {

    // MARK: Properties

    @IBOutlet weak var wotabagTitleItem: UINavigationItem!
    @IBOutlet weak var wotabagStatusLabel: UILabel!
    @IBOutlet weak var wotabagTrackLabel: UILabel!
    @IBOutlet weak var wotabagVolumeLabel: UILabel!
    @IBOutlet weak var wotabagVolumeSlider: UISlider!
    @IBOutlet weak var wotabagRunTestsButton: UIButton!
    @IBOutlet weak var wotabagScrollView: UIScrollView!
    @IBOutlet weak var wotabagColorPickerTextField: UITextField!

    let wotabagColorPicker = UIPickerView()

    var wotabag: Wotabag!

    let batchFactory = BatchFactory(version: "2.0", idGenerator: NumberIdGenerator())
    var key: UInt8 = 0

    var centralManager: CBCentralManager!
    var rpcCharacteristic: CBCharacteristic!
    var responseCallbacks: [Int: (Any) -> ()] = [:]
    var msgManager: MessageManager!

    var playlistViewController: WotabagPlaylistViewController!

    let refreshControl = UIRefreshControl()
    var refreshing: Bool = false

    var colors: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        assert(wotabag != nil)

        wotabagTitleItem.title = wotabag.name;
        wotabagStatusLabel.text = "Waiting for bag connection…"
        wotabagTrackLabel.text = ""

        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        wotabagScrollView.refreshControl = refreshControl

        wotabagColorPicker.delegate = self
        wotabagColorPicker.dataSource = self
        wotabagColorPickerTextField.inputView = wotabagColorPicker
    }

    // MARK: UI Actions

    @objc func refresh() {
        refreshing = true
        getStatus()
    }

    func colorPicker() {
        let toolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneColorPicker))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([spacer, doneButton], animated: false)
        toolbar.isUserInteractionEnabled = true
        wotabagColorPickerTextField.inputAccessoryView = toolbar
    }

    @objc func doneColorPicker() {
        let color = wotabagColorPickerTextField.text ?? "NONE"
        setColor(color)
        wotabagColorPickerTextField.resignFirstResponder()
    }

    @objc func cancelColorPicker() {
        wotabagColorPickerTextField.resignFirstResponder()
    }

    @IBAction func wotabagVolumeSliderChanged(_ sender: Any) {
        let volume = Int(wotabagVolumeSlider.value.rounded())
        setVolume(volume)
    }

    @IBAction func wotabagTestPatternButtonTouchUp(_ sender: Any) {
        runTestPattern()
    }

    @IBAction func wotabagPowerButtonTouchUp(_ sender: Any) {
        powerOff()
    }

    @IBAction func wotabagSetColorButtonTouchUp(_ sender: Any) {
        let color = wotabagColorPickerTextField.text ?? "NONE"
        setColor(color)
    }

    @IBAction func wotabagColorPickerDidBeginEditing(_ sender: Any) {
        colorPicker()
    }

    @IBAction func wotabagPlayButtonTouchUp(_ sender: Any) {
        play()
    }

    @IBAction func wotabagStopButtonTouchUp(_ sender: Any) {
        stop()
    }

    // MARK: - Navigation
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (self.isMovingFromParent) {
            if (centralManager != nil && wotabag.peripheral != nil) {
                centralManager!.cancelPeripheralConnection(wotabag.peripheral!)
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        switch(segue.identifier ?? "") {
        case "WotabagPlaylistSegue":
            guard let wotabagPlaylistViewController = segue.destination as? WotabagPlaylistViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }

            playlistViewController = wotabagPlaylistViewController
            playlistViewController.tableView.delegate = self
        default: break
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: RPC

    func nextKey() -> UInt8 {
        key += 1
        return key
    }

    func getStatus() {
        if (rpcCharacteristic == nil) {
            // Haven't loaded characteristics yet
            return
        }

        let request = GetStatus()
        let batch = batchFactory.create(request)
        let requestObject = batch.requestObject as? [String: Any]
        let reqId = requestObject?["id"] as! Int
        let reqJson = try! JSONSerialization.data(withJSONObject: batch.requestObject, options: [])
        let msg = Message(key: nextKey(), data: reqJson)
        responseCallbacks[reqId] = updateStatus
        sendMsg(msg)
    }

    func updateStatus(_ data: Any) {
        print("Got wotabag status: \(data)")
        let json = data as! [String: Any]
        let result = json["result"] as! [String: Any]
        let status = result["status"] as? String ?? "UNKNOWN"
        if (status == "PLAYING") {
            let current_track = result["current_track"] as? String ?? "UNKNOWN"
            wotabagStatusLabel.text = "Status: Playing \(current_track)"
        }
        else {
            wotabagStatusLabel.text = "Status: \(status)"
        }
        let next_track = result["next_track"] as? String
        if (next_track != nil) {
            wotabagTrackLabel.text = "Next track: \(next_track ?? "")"
        }
        let volume = result["volume"] as? Int
        if (volume == nil) {
            wotabagVolumeLabel.text = "Volume: UNKNOWN"
            wotabagVolumeSlider.isEnabled = false
            wotabagVolumeSlider.setValue(Float(0), animated: false)
        }
        else {
            wotabagVolumeLabel.text = "Volume: \(volume!)"
            wotabagVolumeSlider.isEnabled = true
            wotabagVolumeSlider.setValue(Float(volume ?? 0), animated: true)
        }

        if (refreshing) {
            refreshControl.endRefreshing()
            refreshing = false
        }
    }

    func setVolume(_ volume: Int) {
        if (rpcCharacteristic == nil) {
            // Haven't loaded characteristics yet
            return
        }

        let request = SetVolume(volume: volume)
        let batch = batchFactory.create(request)
        let requestObject = batch.requestObject as? [String: Any]
        let reqId = requestObject?["id"] as! Int
        let reqJson = try! JSONSerialization.data(withJSONObject: batch.requestObject, options: [])
        let msg = Message(key: nextKey(), data: reqJson)
        responseCallbacks[reqId] = updateVolume
        sendMsg(msg)
    }

    func updateVolume(_ data: Any) {
        print("Got wotabag volume: \(data)")
        let json = data as! [String: Any]
        let result = json["result"] as? Int
        if (result == nil) {
            wotabagVolumeLabel.text = "Volume: UNKNOWN"
            wotabagVolumeSlider.isEnabled = false
            wotabagVolumeSlider.setValue(Float(0), animated: false)
        }
        else {
            wotabagVolumeLabel.text = "Volume: \(result!)"
            wotabagVolumeSlider.isEnabled = true
            wotabagVolumeSlider.setValue(Float(result ?? 0), animated: true)
        }
    }

    func runTestPattern() {
        if (rpcCharacteristic == nil) {
            // Haven't loaded characteristics yet
            return
        }

        let request = TestPattern()
        let batch = batchFactory.create(request)
        let reqJson = try! JSONSerialization.data(withJSONObject: batch.requestObject, options: [])
        let msg = Message(key: nextKey(), data: reqJson)
        sendMsg(msg)
    }

    func powerOff() {
        if (rpcCharacteristic == nil) {
            // Haven't loaded characteristics yet
            return
        }

        let request = PowerOff()
        let batch = batchFactory.create(request)
        let reqJson = try! JSONSerialization.data(withJSONObject: batch.requestObject, options: [])
        let msg = Message(key: nextKey(), data: reqJson)
        sendMsg(msg)
    }

    func getPlaylist() {
        if (rpcCharacteristic == nil) {
            // Haven't loaded characteristics yet
            return
        }

        let request = GetPlaylist()
        let batch = batchFactory.create(request)
        let requestObject = batch.requestObject as? [String: Any]
        let reqId = requestObject?["id"] as! Int
        let reqJson = try! JSONSerialization.data(withJSONObject: batch.requestObject, options: [])
        let msg = Message(key: nextKey(), data: reqJson)
        responseCallbacks[reqId] = updatePlaylist
        sendMsg(msg)
    }

    func updatePlaylist(_ data: Any) {
        print("Got wotabag playlist: \(data)")
        let json = data as! [String: Any]
        let result = json["result"] as! [String]
        if (playlistViewController != nil) {
            print("updating playlist table")

            playlistViewController.playlist.removeAll(keepingCapacity: false)
            for track in result {
                print(track)
                playlistViewController.playlist.append(track)
            }

            playlistViewController.tableView.reloadData()
        }
        else {
            print("no playlist view controller")
        }
    }

    func getColors() {
        if (rpcCharacteristic == nil) {
            // Haven't loaded characteristics yet
            return
        }

        let request = GetColors()
        let batch = batchFactory.create(request)
        let requestObject = batch.requestObject as? [String: Any]
        let reqId = requestObject?["id"] as! Int
        let reqJson = try! JSONSerialization.data(withJSONObject: batch.requestObject, options: [])
        let msg = Message(key: nextKey(), data: reqJson)
        responseCallbacks[reqId] = updateColors
        sendMsg(msg)
    }

    func updateColors(_ data: Any) {
        print("Got wotabag colors: \(data)")
        let json = data as! [String: Any]
        let result = json["result"] as! [String]

        for color in result {
            colors.append(color)
        }

        wotabagColorPicker.reloadAllComponents()
    }

    func setColor(_ color: String) {
        if (rpcCharacteristic == nil) {
            // Haven't loaded characteristics yet
            return
        }

        let request = SetColor(color: color)
        let batch = batchFactory.create(request)
        let reqJson = try! JSONSerialization.data(withJSONObject: batch.requestObject, options: [])
        let msg = Message(key: nextKey(), data: reqJson)
        sendMsg(msg)
    }

    func play() {
        if (rpcCharacteristic == nil) {
            // Haven't loaded characteristics yet
            return
        }

        let request = Play()
        let batch = batchFactory.create(request)
        let reqJson = try! JSONSerialization.data(withJSONObject: batch.requestObject, options: [])
        let msg = Message(key: nextKey(), data: reqJson)
        sendMsg(msg)
    }

    func stop() {
        if (rpcCharacteristic == nil) {
            // Haven't loaded characteristics yet
            return
        }

        let request = Stop()
        let batch = batchFactory.create(request)
        let reqJson = try! JSONSerialization.data(withJSONObject: batch.requestObject, options: [])
        let msg = Message(key: nextKey(), data: reqJson)
        sendMsg(msg)
    }

    func playIndex(_ index: Int) {
        if (rpcCharacteristic == nil) {
            // Haven't loaded characteristics yet
            return
        }

        let request = PlayIndex(index: index)
        let batch = batchFactory.create(request)
        let reqJson = try! JSONSerialization.data(withJSONObject: batch.requestObject, options: [])
        let msg = Message(key: nextKey(), data: reqJson)
        sendMsg(msg)
    }

    // Write the specified message as a sequence of SDP datagrams to the wotabag GATT RPC characteristic
    func sendMsg(_ msg: Message) {
        if rpcCharacteristic == nil {
            print("Cannot send message, no BLE RPC characteristic available")
            return
        }

        print("Sending message: \(msg.data)")

        let dgramView = msg.datagrams(datagramMaxSize: iosMTU)

        for i in 0..<dgramView.endIndex {
            let dgram = dgramView[i]
            wotabag.peripheral?.writeValue(dgram.encoded, for: rpcCharacteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }

    // Read a sequence of SDP datagrams from the wotabag GATT RPC characteristic until a full message is received,
    // and then pass the response to the specified callback.
    func readResponse(_ msg: Message) {
        let data = try? JSONSerialization.jsonObject(with: msg.data, options: [])
        if (data != nil) {
            let response = data as! [String: Any]
            let reqId = response["id"] as! Int
            let callback = responseCallbacks[reqId]
            if (callback != nil) {
                callback!(data as Any)
                responseCallbacks.removeValue(forKey: reqId)
            }
        }
    }
}

extension WotabagRemoteViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == wotabagRPCCharacteristicUUID {
                rpcCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
            print(characteristic)
        }

        getStatus()
        getPlaylist()
        getColors()
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case wotabagRPCCharacteristicUUID:
            if (msgManager == nil) {
                msgManager = MessageManager(onMessage: readResponse)
            }
            do {
                if (characteristic.value != nil) {
                    try msgManager.process(datagramData: characteristic.value!)
                }
            } catch {
                print("Ignoring non-RPC datagram")
            }
        default:
            print("Ignoring value for unexpected RPC characteristic \(characteristic.uuid)")
        }
    }
}

extension WotabagRemoteViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return colors[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        wotabagColorPickerTextField.text = colors[row]
    }
}

extension WotabagRemoteViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return colors.count
    }
}

extension WotabagRemoteViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        playIndex(index)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
