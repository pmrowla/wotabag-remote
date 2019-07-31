//
//  WotabagPlaylistViewController.swift
//  wotabag-remote
//
//  Created by Peter Rowlands on 2019/08/26.
//  Copyright © 2019 Peter Rowlands. All rights reserved.
//

import UIKit

class WotabagPlaylistViewController: UITableViewController {

    // MARK: Properties
    var playlist: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("\(playlist.count) rows in table")
        return playlist.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "WotabagTracklistCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? WotabagTracklistCell else {
            fatalError("Dequeued cell not a WotabagTracklistCell instance")
        }

        let track = playlist[indexPath.row]
        cell.wotabagTracklistLabel.text = track

        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
