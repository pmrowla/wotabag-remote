//
//  WotabagBrowserTableViewCell.swift
//  wotabag-remote
//
//  Created by Peter Rowlands on 2019/08/09.
//  Copyright © 2019 Peter Rowlands. All rights reserved.
//

import UIKit

class WotabagBrowserTableViewCell: UITableViewCell {

    // MARK: Properties
    @IBOutlet weak var wotabagLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
