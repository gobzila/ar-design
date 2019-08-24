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
import QuartzCore

let DETECT_MESSAGE = "Wait for horizontal plane detection"
let TAP_MESSAGE = "Tap to place "
let SELECT_MESSAGE = "Select a model"


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

public protocol DataBackDelegate: class {
    func setModel(model : Model)
}

class ARController: UIViewController, ARSCNViewDelegate, DataBackDelegate {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet var addButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet var sceneView: ARSCNView!
    
    var modelNodes = [SCNNode]()
    var currentModel: Model?
    var currentNode: SCNNode!
    var firstAngleY: Float?
    var planeGeometry: SCNPlane!
    var isPlaneVisible = true
    let planeIdentifiers = [UUID]()
    var anchors = [ARAnchor]()
    var planes = [SCNPlane]()
    var sceneLight:SCNLight!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyDesign()
        
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = false
        sceneView.debugOptions = [.showWireframe, .showBoundingBoxes, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
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
        if currentModel == nil { return }
        
        let touch = touches.first
        let location = touch?.location(in: sceneView)
        
        addModelAtLocation(location: location!, model: currentModel!)
        currentModel = nil
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
            planes.append(planeGeometry)
            updatePlaneVisibility()
            
            let planeNode = SCNNode(geometry: planeGeometry)
            planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
            updatePlaneMaterial()
            
            node?.addChildNode(planeNode)
            anchors.append(planeAnchor)
            if anchors.count == 1 {
                messageLabel.show(message: SELECT_MESSAGE)
            }
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
                        updatePlaneMaterial()
                    }
                }
            }
        }
    }
    
    @objc func detectModel(press: UILongPressGestureRecognizer) {
        if (currentNode != nil || currentModel != nil) { return }
        let location = press.location(in: sceneView)
        let node = getNodeAtLocation(location: location)
        if node != nil {
            currentNode = node
            confirmButton.isHidden = false
            isPlaneVisible = true
            updatePlaneVisibility();
        }
    }
    
    @objc func rotateModel(_ gesture: UIRotationGestureRecognizer) {
        if(currentNode == nil) { return }
        let rotation = Float(gesture.rotation)

        if gesture.state == .began {
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
    
    func updatePlaneMaterial() {
        let material = self.planeGeometry.materials.first!
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(self.planeGeometry.width), Float(self.planeGeometry.height), 1)
    }
    
    func updatePlaneVisibility() {
        for plane in planes {
            if isPlaneVisible {
                plane.firstMaterial?.diffuse.contents = UIImage(named: "background")!.resizableImage(withCapInsets: .zero)
            } else {
                plane.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0)
            }
        }
    }
    
    func getNodeAtLocation(location: CGPoint) -> SCNNode? {
        let hitResult = sceneView.hitTest(location, options: nil)

        if !hitResult.isEmpty {
            let result = hitResult.first!
            if let currentModel = result.node.geometry {
                if !(currentModel is SCNPlane) {
                    if modelNodes.first(where: {$0.name == result.node.name}) != nil {
                        return result.node
                    }
                    for node in modelNodes {
                        for child in node.childNodes {
                            if child.name == result.node.name {
                                return node
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    
    func addModelAtLocation(location: CGPoint, model: Model) {
        guard anchors.count > 0 else { print("anchors are not created yet!"); return }
        
        let hitResults = sceneView.hitTest(location, types: .existingPlane)
        guard let hitTestResult = hitResults.first else { return }
        
        let columns = hitTestResult.worldTransform.columns.3
        
        guard let modelScene = SCNScene(named: model.path) else { return }
        let modelNode = SCNNode()
        for childNode in modelScene.rootNode.childNodes {
            for child in childNode.childNodes {
                if (child.geometry != nil) {
                    childNode.name = model.id
                    modelNodes.append(childNode)
                    break
                }
            }
            modelNode.addChildNode(childNode)
        }
        currentNode = modelNode.childNode(withName: model.id, recursively: false)
        let x = columns.x
        let y = columns.y + 0.05
        let z = columns.z + Float(getModelDimensions(currentNode).z / 2)
        currentNode.position = SCNVector3(x,y,z)
        
        sceneView.scene.rootNode.addChildNode(modelNode)
        messageLabel.hide()
        confirmButton.isHidden = false
    }
    
    func updateNodeAtLocation(location: CGPoint, node: SCNNode) {
        guard anchors.count > 0 else { print("anchors are not created yet!"); return }
        
        let hitResults = sceneView.hitTest(location, types: .existingPlane)
        
        if hitResults.count > 0 {
            let result = hitResults.first!
            var newLocation = SCNVector3(x: result.worldTransform.columns.3.x, y: node.position.y, z: result.worldTransform.columns.3.z)
            newLocation.z += getModelDimensions(node).z / 2
            node.simdPosition = float3(newLocation.x, newLocation.y, newLocation.z)
        }
    }
    
    func getModelDimensions(_ node: SCNNode) -> SCNVector3 {
        let (minVec, maxVec) = node.boundingBox
        let y = (maxVec.x - minVec.x) * node.scale.x
        let x = (maxVec.y - minVec.y) * node.scale.y
        let z = (maxVec.z - minVec.z) * node.scale.z
        
        return SCNVector3(x: x, y: y, z: z)
    }
 
    @IBAction func onConfirmButtonPress(_ sender: Any) {
        currentNode = nil
        isPlaneVisible = false
        updatePlaneVisibility()
        messageLabel.hide()
        confirmButton.isHidden = true
    }
    
    func applyDesign() {
        addButton.applyDesign()
        homeButton.applyDesign()
        confirmButton.applyDesign()
        confirmButton.isHidden = true
        
        messageLabel.backgroundColor = UIColor(white: 1, alpha: 0.7)
        messageLabel.layer.cornerRadius = 10
        messageLabel.show(message: DETECT_MESSAGE)
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
    
    func setModel(model: Model) {
        self.currentModel = model
        currentNode = nil
        messageLabel.show(message: TAP_MESSAGE + model.name + " model")
        isPlaneVisible = true
        updatePlaneVisibility()
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
