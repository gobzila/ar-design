//
//  ViewController.swift
//  AR Design
//
//  Created by Ioan Gabriel Borșan on 17/07/2019.
//  Copyright © 2019 Ioan Gabriel Borșan. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

extension UIButton {
    func applyDesign(){
        self.layer.backgroundColor = UIColor.white.cgColor
        self.layer.cornerRadius = self.frame.height / 2;
        self.setTitleColor(UIColor.black, for: .normal)
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowRadius = 4
        self.layer.shadowOpacity = 0.6
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
    }
}

public protocol DataBackDelegate: class {
    func saveModel (model : String)
}

class ARController: UIViewController, ARSCNViewDelegate, DataBackDelegate {
    
    @IBOutlet var addButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet var sceneView: ARSCNView!
    
    var model: String?
    var currentNode: SCNNode!
    var firstAngleY: Float?
    var planeGeometry: SCNPlane!
    let planeIdentifiers = [UUID]()
    var anchors = [ARAnchor]()
    var sceneLight:SCNLight!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        addButton.applyDesign()
        homeButton.applyDesign()

        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
        
        sceneView.autoenablesDefaultLighting = false
        
        let longPressGesturerecogn = UILongPressGestureRecognizer(target: self, action: #selector(detectModel(press:)))
        longPressGesturerecogn.minimumPressDuration = 1
        sceneView.addGestureRecognizer(longPressGesturerecogn)
        sceneView.addGestureRecognizer(UIRotationGestureRecognizer(target: self, action: #selector(rotateModel(_:))))
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        sceneLight = SCNLight()
        sceneLight.type = .omni
        
        let lightNode = SCNNode()
        lightNode.light = sceneLight
        lightNode.position = SCNVector3(x:0, y:10, z:2)
        
        sceneView.scene.rootNode.addChildNode(lightNode)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let location = touch?.location(in: sceneView)
        if model == nil { return }
        
        addNodeAtLocation(location: location!)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if currentNode == nil { return }
        let touch = touches.first
        let location = touch?.location(in: sceneView)
        
        updateNodeAtLocation(location: location!, node: currentNode)
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if let estimate = self.sceneView.session.currentFrame?.lightEstimate {
            sceneLight.intensity = estimate.ambientIntensity
        }
    }
    
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        var node: SCNNode?

        if let planeAnchor = anchor as? ARPlaneAnchor {
            node = SCNNode()
            planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            planeGeometry.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.4)

            let planeNode = SCNNode(geometry: planeGeometry)
            planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
            
            updateMaterial()
            
            node?.addChildNode(planeNode)
            anchors.append(planeAnchor)
        }
        
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            if anchors.contains(planeAnchor) {
                if node.childNodes.count > 0 {
                    let planeNode = node.childNodes.first!
                    planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
                    
                    if let plane = planeNode.geometry as? SCNPlane {
                        plane.width = CGFloat(planeAnchor.extent.x)
                        plane.height = CGFloat(planeAnchor.extent.z)
                        updateMaterial()
                    }
                }
            }
        }
    }
    
    @objc func detectModel(press: UILongPressGestureRecognizer) {
        if (currentNode != nil || model != nil) { return }
        let location = press.location(in: sceneView)
        let node = getNodeAtLocation(location: location)
        if node != nil {
            updateModelAndMaterial(modelNode: node);
        }
    }
    
    @objc func rotateModel(_ gesture: UIRotationGestureRecognizer) {
        if(currentNode == nil) { return }
        let rotation = Float(gesture.rotation)

        if gesture.state == .began {
            print(getModelDimensions(currentNode))
            firstAngleY = currentNode.eulerAngles.y
            currentNode.eulerAngles.y = firstAngleY! - rotation
        }
        if gesture.state == .changed {
            currentNode.eulerAngles.y = firstAngleY! - rotation
        }
        
        if(gesture.state == .ended) {
            currentNode.eulerAngles.y = firstAngleY! - rotation
        }
    }
    
    func updateMaterial() {
        let material = self.planeGeometry.materials.first!
        
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(self.planeGeometry.width), Float(self.planeGeometry.height), 1)
    }
    
    func updateModelAndMaterial(modelNode: SCNNode? = nil) {
        model = nil
        if modelNode == nil {
            planeGeometry.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0)
            currentNode = nil
        } else {
            planeGeometry.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.4)
            currentNode = modelNode
        }
    }
    
    func getNodeAtLocation(location: CGPoint) -> SCNNode? {
        let hitResult = sceneView.hitTest(location, options: nil)

        if !hitResult.isEmpty {
            let result = hitResult.first!
            if let model = result.node.geometry {
                if !(model is SCNPlane) {
                    return result.node
                }
            }
        }
        return nil
    }
    
    func addNodeAtLocation(location: CGPoint) {
        guard anchors.count > 0 else { print("anchors are not created yet!"); return }
        
        let hitResults = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        
        if hitResults.count > 0 {
            let result = hitResults.first!
            var newLocation = SCNVector3(x: result.worldTransform.columns.3.x, y: result.worldTransform.columns.3.y + 0.05, z: result.worldTransform.columns.3.z)
            
            guard let modelScene = SCNScene(named: model!) else { return }
            let modelNode = SCNNode()
            print(getModelDimensions(modelNode))
            let modelSceneChildNodes = modelScene.rootNode.childNodes
            
            for childNode in modelSceneChildNodes {
                modelNode.addChildNode(childNode)
            }
            
            newLocation.z += getModelDimensions(modelNode).z/2
            
            modelNode.position = newLocation
            
            currentNode = modelNode
            
            sceneView.scene.rootNode.addChildNode(modelNode)
            
            updateModelAndMaterial()
        }
    }
    
    func updateNodeAtLocation(location: CGPoint, node: SCNNode) {
        guard anchors.count > 0 else { print("anchors are not created yet!"); return }
        
        let hitResults = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        
        if hitResults.count > 0 {
            let result = hitResults.first!
            let newLocation = SCNVector3(x: result.worldTransform.columns.3.x, y: node.position.y, z: result.worldTransform.columns.3.z)
            print(getModelDimensions(node))

//            newLocation.z -= getModelDimensions(node).z / 2
            
            node.simdPosition = float3(newLocation.x, newLocation.y, newLocation.z)
            
//          updateModelAndMaterial()
        }
    }
    
    func getModelDimensions(_ node: SCNNode) -> SCNVector3 {
        let (minVec, maxVec) = node.boundingBox
        let x = maxVec.y - minVec.y
        let y = maxVec.x - minVec.x
        let z = maxVec.z - minVec.z
        
        return SCNVector3(x: x, y: y, z: z)
    }
 
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func saveModel(model: String) {
        self.model = model
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "SelectModel" {
            guard let listController = segue.destination as? ModelListController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            listController.dataBackDelegate = self
        }
    }
}
