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
    weak var dataBackDelegate: DataBackDelegate?
    private var models = [Model]()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadModels()
    }
    
    func loadModels() {
        var image = UIImage(named: "wooden-coffe-table")!
        var model = Model(id: "wooden-coffe-table", name: "Wooden Coffe Table", image: image, path: "art.scnassets/wooden-coffe-table.scn")!
        models.append(model)
        image = UIImage(named: "eames-chair")!
        model = Model(id: "eames-chair", name: "Eames Chair", image: image, path: "art.scnassets/eames-chair.scn")!
        models.append(model)
        image = UIImage(named: "vitra-chair")!
        model = Model(id: "vitra-chair", name: "Vitra Chair", image: image, path: "art.scnassets/vitra-chair.scn")!
        models.append(model)
        image = UIImage(named: "linda-coffee-table")!
        model = Model(id: "linda-coffee-table", name: "Linda Coffee Table", image: image, path: "art.scnassets/linda-coffee-table.scn")!
        models.append(model)
        image = UIImage(named: "lova-bed")!
        model = Model(id: "lova-bed", name: "Lova Bed", image: image, path: "art.scnassets/lova-bed.scn")!
        models.append(model)
        image = UIImage(named: "jean-armchair")!
        model = Model(id: "jean-armchair", name: "Jean Armchair", image: image, path: "art.scnassets/jean-armchair.scn")!
        models.append(model)
        image = UIImage(named: "ship")!
        model = Model(id: "ship", name: "Ship", image: image, path: "art.scnassets/ship.scn")!
        models.append(model)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.models.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ModelViewCell", for: indexPath) as? ModelViewCell  else {
            fatalError("The dequeued cell is not an instance of modelViewCell.")
        }
        let model = self.models[indexPath.row]
        cell.nameLabel.text = model.name
        cell.photoView.image = model.image
        cell.selectionStyle = .none

        return cell
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        
        let button = sender
        let cell = button.superview!.superview! as! ModelViewCell
        let indexPath = tableView.indexPath(for: cell)
        let selectedModel = models[indexPath!.row]
        dataBackDelegate?.setModel(model: selectedModel)
        navigationController?.popViewController(animated: true)
    }
    
}
