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

public protocol DataBackDelegate: class {
    func setModel(model : Model)
}

class ARController: UIViewController, ARSCNViewDelegate, DataBackDelegate {
    
    let DETECT_MESSAGE = "Move the camera to detect the horizontal plane"
    let TAP_MESSAGE = "Tap to place "
    let SELECT_MESSAGE = "Select a model"
    let EDIT_MESSAGE = "(Edit Mode) Move or rotate the model"
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var ssButton: UIButton!
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
    var Y: Float?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeComponents()
        
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = false
//        sceneView.debugOptions = [.showWireframe, .showBoundingBoxes, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
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
    
    func initializeComponents() {
        addButton.applyDesign1()
        addButton.isHidden = true
        homeButton.applyDesign1()
        confirmButton.applyDesign1()
        confirmButton.isHidden = true
        deleteButton.applyDesign1()
        deleteButton.isHidden = true
        ssButton.applyDesign1()
        ssButton.isHidden = true
        messageLabel.backgroundColor = UIColor(white: 1, alpha: 0.7)
        messageLabel.layer.cornerRadius = 10
        messageLabel.show(message: DETECT_MESSAGE)
    }
    
    @IBAction func onConfirmButtonPress(_ sender: Any) {
        currentNode = nil
        isPlaneVisible = false
        updatePlaneVisibility()
        messageLabel.hide()
        confirmButton.isHidden = true
        deleteButton.isHidden = true
        ssButton.isHidden = false
    }
    
    @IBAction func onDeleteButtonPress(_ sender: Any) {
        currentNode.removeFromParentNode()
        currentNode = nil
        isPlaneVisible = false
        updatePlaneVisibility()
        messageLabel.hide()
        confirmButton.isHidden = true
        deleteButton.isHidden = true
        ssButton.isHidden = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if currentModel == nil { return }
        
        let touch = touches.first
        let location = touch?.location(in: sceneView)
        addModelAtLocation(location: location!, model: currentModel!)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if currentNode == nil { return }
        
        let touch = touches.first
        let location = touch?.location(in: sceneView)
        updateNodeAtLocation(location: location!, node: currentNode)
    }

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
                DispatchQueue.main.async {
                    self.addButton.isHidden = false
                    self.messageLabel.show(message: self.SELECT_MESSAGE)
                }
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
            deleteButton.isHidden = false
            ssButton.isHidden = true
            isPlaneVisible = true
            updatePlaneVisibility();
            messageLabel.show(message: EDIT_MESSAGE)
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
    
    func updateModelColor(color: String?) {
        if color == "default-texture" {
            return
        }
        let imageMaterial = SCNMaterial()
        imageMaterial.isDoubleSided = false
        imageMaterial.diffuse.contents = UIImage(named: color!)
        if currentNode!.geometry != nil {
        currentNode!.geometry?.materials = [imageMaterial]
        }
        for childNode in currentNode!.childNodes {
            if childNode.geometry != nil {
            childNode.geometry?.materials = [imageMaterial]
            }
        }
    }
    
    func setModel(model: Model) {
        self.currentModel = model
        currentNode = nil
        messageLabel.show(message: TAP_MESSAGE + model.name + " model")
        isPlaneVisible = true
        updatePlaneVisibility()
    }
    
    func getNodeDimensions(_ node: SCNNode) -> SCNVector3 {
        let (minVec, maxVec) = node.boundingBox
        let x = (maxVec.x - minVec.x) * node.scale.x
        let y = (maxVec.y - minVec.y) * node.scale.y
        let z = (maxVec.z - minVec.z) * node.scale.z
        
        return SCNVector3(x: x, y: y, z: z)
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
        
        let hitResults = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        guard let hitTestResult = hitResults.first else { return }
        
        let columns = hitTestResult.worldTransform.columns.3
        
        guard let modelScene = SCNScene(named: model.path) else { return }
        let modelNode = SCNNode()
        
        for childNode in modelScene.rootNode.childNodes {
            if (childNode.geometry != nil) {
                childNode.name = model.id
                currentNode = childNode
                modelNodes.append(childNode)
            } else {
                for child in childNode.childNodes {
                    if (child.geometry != nil) {
                        childNode.name = model.id
                        currentNode = childNode
                        modelNodes.append(childNode)
                        break
                    }
                }
            }
            modelNode.addChildNode(childNode)
        }
        let x = columns.x
        let y = columns.y + 0.005
        let z = columns.z
        currentNode.position = SCNVector3(x,y,z)
        currentNode.scale.x = currentNode.scale.x * (currentModel?.scale.x)!
        currentNode.scale.y = currentNode.scale.y * (currentModel?.scale.y)!
        currentNode.scale.z = currentNode.scale.z * (currentModel?.scale.z)!
        updateModelColor(color: model.color!)
        sceneView.scene.rootNode.addChildNode(modelNode)
        currentModel = nil
        messageLabel.show(message: EDIT_MESSAGE)
        confirmButton.isHidden = false
        deleteButton.isHidden = false
    }
    
    func updateNodeAtLocation(location: CGPoint, node: SCNNode) {
        guard anchors.count > 0 else { print("anchors are not created yet!"); return }
        
        let hitResults = sceneView.hitTest(location, types: .existingPlane)
        if hitResults.count > 0 {
            let result = hitResults.first!
            let newLocation = SCNVector3(x: result.worldTransform.columns.3.x, y: node.position.y, z: result.worldTransform.columns.3.z)
            node.simdPosition = float3(newLocation.x, newLocation.y, newLocation.z)
        }
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "SelectModel" {
            guard let listController = segue.destination as? ModelListController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            listController.arController = self
        }
    }
    
    public var screenWidth: CGFloat {
        return UIScreen.main.bounds.width
    }
    
    public var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }
    
    func snapshot(of rect: CGRect? = nil) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.sceneView.bounds.size, self.sceneView.isOpaque, 0)
        self.sceneView.drawHierarchy(in: self.sceneView.bounds, afterScreenUpdates: true)
        let fullImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let image = fullImage, let rect = rect else { return fullImage }
        let scale = image.scale
        let scaledRect = CGRect(x: rect.origin.x * scale, y: rect.origin.y * scale, width: rect.size.width * scale, height: rect.size.height * scale)
        guard let cgImage = image.cgImage?.cropping(to: scaledRect) else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }
    
    @IBAction func takeScreenShot(_ sender: UIButton) {
        let screenShot = snapshot(of: CGRect(x: 0, y: 60, width: screenWidth, height: screenHeight - 60))
        UIImageWriteToSavedPhotosAlbum(screenShot!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)

    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved", message: "Image saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
}
