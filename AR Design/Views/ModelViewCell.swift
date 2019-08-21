//
//  ModelViewCell.swift
//  AR Design
//
//  Created by Ioan Gabriel Borșan on 23/07/2019.
//  Copyright © 2019 Ioan Gabriel Borșan. All rights reserved.
//

import UIKit

class ModelViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var photoView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
