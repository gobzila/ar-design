//
//  Label.swift
//  AR Design
//
//  Created by Ioan Gabriel Borșan on 29/08/2019.
//  Copyright © 2019 Ioan Gabriel Borșan. All rights reserved.
//

import UIKit

extension UILabel {
    func show(message: String) {
        DispatchQueue.main.async {
            self.text = message
            self.isHidden = false
        }
    }
    
    func hide() {
        self.text = ""
        self.isHidden = true
    }
}
