//
//  Model.swift
//  AR Design
//
//  Created by Ioan Gabriel Borșan on 23/07/2019.
//  Copyright © 2019 Ioan Gabriel Borșan. All rights reserved.
//

import Foundation
import UIKit
import os.log

class Model: NSObject, NSCoding {
    
    var id: String
    var name: String
    var image: UIImage?
    var path: String
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("models")
    
    init?(id: String, name: String, image: UIImage, path: String) {
        self.id = id
        self.name = name
        self.image = image
        self.path = path
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(id, forKey: "id")
        coder.encode(name, forKey: "name")
        coder.encode(image, forKey: "image")
        coder.encode(path, forKey: "path")
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let id = aDecoder.decodeObject(forKey: "id") as? String
        let name = aDecoder.decodeObject(forKey: "name") as? String
        let image = aDecoder.decodeObject(forKey: "image") as? UIImage
        let path = aDecoder.decodeObject(forKey: "path") as? String
        
        self.init(id: id!, name: name!, image: image!, path: path!)
        
    }
    
}
