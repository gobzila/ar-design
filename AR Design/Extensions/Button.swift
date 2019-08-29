//
//  File.swift
//  AR Design
//
//  Created by Ioan Gabriel Borșan on 29/08/2019.
//  Copyright © 2019 Ioan Gabriel Borșan. All rights reserved.
//

import UIKit

extension UIButton {
    func applyDesign1(){
        self.layer.backgroundColor = UIColor.white.cgColor
        self.layer.cornerRadius = self.frame.height / 2;
        self.setTitleColor(UIColor.black, for: .normal)
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowRadius = 4
        self.layer.shadowOpacity = 0.6
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
    }
    
    func applyDesign2(){
        self.layer.backgroundColor = UIColor.black.cgColor
        self.layer.cornerRadius = self.frame.height / 2;
        self.setTitleColor(UIColor.white, for: .normal)
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowRadius = 4
        self.layer.shadowOpacity = 0.6
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
    }
}
