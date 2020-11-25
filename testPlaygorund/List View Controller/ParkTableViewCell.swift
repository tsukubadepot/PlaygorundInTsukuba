//
//  ParkTableViewCell.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/11/25.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import UIKit

class ParkTableViewCell: UITableViewCell {
    @IBOutlet weak var imageThumbnailView: UIImageView! {
        didSet {
            imageThumbnailView.contentMode = .scaleAspectFill
        }
    }
    
    @IBOutlet weak var parknameLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var equipmentCountLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
