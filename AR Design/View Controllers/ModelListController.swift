//
//  ModelListController.swift
//  AR Design
//
//  Created by Ioan Gabriel Borșan on 23/07/2019.
//  Copyright © 2019 Ioan Gabriel Borșan. All rights reserved.
//

import UIKit
import SceneKit

class ModelListController: UITableViewController{
    private var models = [Model]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let image = UIImage(named: "wooden-coffe-table")!
        let model = Model(id: "wooden-coffe-table", name: "Wooden Coffe Table", image: image)!
        models.append(model)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.models.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ModelViewCell", for: indexPath) as? ModelViewCell  else {
            fatalError("The dequeued cell is not an instance of modelViewCell.")
        }
        let model = self.models[indexPath.row]
        
        cell.nameLabel.text = model.name
        cell.photoView.image = model.image

        return cell
    }
}
