//
//  TableViewCell.swift
//  DBFM
//
//  Created by apple on 15/12/3.
//  Copyright © 2015年 pz1943. All rights reserved.
//

import UIKit

class ListTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var tileLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var favoriteSwitch: UISwitch!

}
