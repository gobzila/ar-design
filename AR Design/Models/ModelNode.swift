//
//  ModelNode.swift
//  AR Design
//
//  Created by Ioan Gabriel Borșan on 23/07/2019.
//  Copyright © 2019 Ioan Gabriel Borșan. All rights reserved.
//

import SceneKit

class ModelNode: SCNNode {
    
    override init() {
        super.init()
        
        guard let carScene = SCNScene(named: "ship.scn") else { return }
        let carNode = SCNNode()
        let carSceneChildNodes = carScene.rootNode.childNodes
        
        for childNode in carSceneChildNodes {
            carNode.addChildNode(childNode)
        }
        
//        self.geo
//        carNode.position = SCNVector3(x, y, z)
//        carNode.scale = SCNVector3(0.5, 0.5, 0.5)
//        sceneView.scene.rootNode.addChildNode(carNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
