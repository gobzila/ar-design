//
//  ModelController.swift
//  AR Design
//
//  Created by Ioan Gabriel Borșan on 28/08/2019.
//  Copyright © 2019 Ioan Gabriel Borșan. All rights reserved.
//

import UIKit
import SceneKit

class ModelController: UIViewController {
    weak var arController: DataBackDelegate?

    @IBOutlet weak var sceneView: SCNView!
    var model: Model?
    var initialMaterial: SCNMaterial?
    var modelNode: SCNNode?
    var initialMaterials = [[SCNMaterial]]()
    var initialWidthScale: Float?
    var initialHeightScale: Float?
    var initialDepthScale: Float?
    
    @IBOutlet weak var width: UILabel!
    @IBOutlet weak var height: UILabel!
    @IBOutlet weak var depth: UILabel!
    @IBOutlet weak var colorLabel: UILabel!
    @IBOutlet weak var color1: UIButton!
    @IBOutlet weak var color2: UIButton!
    @IBOutlet weak var color3: UIButton!
    @IBOutlet weak var color4: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.scene = SCNScene()
        sceneView.backgroundColor = UIColor.white
        sceneView.allowsCameraControl = true
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
        sceneView.scene?.rootNode.addChildNode(cameraNode)
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 2)
        sceneView.scene?.rootNode.addChildNode(lightNode)

        initModel()
        initColors()
        continueButton.applyDesign1()
    }
    
    func initModel() {
        guard let modelScene = SCNScene(named: model!.path) else { return }
        for childNode in modelScene.rootNode.childNodes {
            if (childNode.geometry != nil) {
                childNode.name = model?.id
                modelNode = childNode
            } else {
                for child in childNode.childNodes {
                    if (child.geometry != nil) {
                        childNode.name = model?.id
                        modelNode = childNode
                    }
                }
            }
        }
        
        modelNode?.position.x = 0
        modelNode?.position.y = -0.5
        modelNode?.position.z = 0
        initialWidthScale = modelNode?.scale.x
        initialHeightScale = modelNode?.scale.y
        initialDepthScale = modelNode?.scale.z
        sceneView.scene?.rootNode.addChildNode(modelNode!)
        updateDimensions()
    }
    
    func initColors() {
        if model?.colors == nil {
            colorLabel.isHidden = true
            color1.isHidden = true
            color2.isHidden = true
            color3.isHidden = true
            color4.isHidden = true
            return
        }
        if (model?.colors!.count)! < 1 {
            colorLabel.isHidden = true
            color1.isHidden = true
            color2.isHidden = true
            color3.isHidden = true
            color4.isHidden = true
            return
        }
        let colorImage1 = UIImage(named: model!.colors![0])
        color1.applyDesign1()
        color1.setBackgroundImage(colorImage1, for: .normal)
        if (model?.colors!.count)! < 2 {
            color2.isHidden = true
            color3.isHidden = true
            color4.isHidden = true
            return
        }
        let colorImage2 = UIImage(named: model!.colors![1])
        color2.applyDesign1()
        color2.setBackgroundImage(colorImage2, for: .normal)
        if (model?.colors!.count)! < 3 {
            color3.isHidden = true
            color4.isHidden = true
            return
        }
        let colorImage3 = UIImage(named: model!.colors![2])
        color3.applyDesign1()
        color3.setBackgroundImage(colorImage3, for: .normal)
        if (model?.colors!.count)! < 4 {
            color4.isHidden = true
            return
        }
        let colorImage4 = UIImage(named: model!.colors![3])
        color4.applyDesign1()
        color4.setBackgroundImage(colorImage4, for: .normal)
    }
    
    @IBAction func changeWidth(_ sender: UISlider) {
        model!.scale.x = sender.value
        updateDimensions()
    }

    @IBAction func changeHeight(_ sender: UISlider) {
        model!.scale.y = sender.value
        updateDimensions()
    }
    
    @IBAction func changeDepth(_ sender: UISlider) {
        model!.scale.z = sender.value
        updateDimensions()
    }
    
    @IBAction func onColor1Press(_ sender: UIButton) {
        updateColor(color: model!.colors![0])
    }
    
    @IBAction func onColor2Press(_ sender: UIButton) {
        updateColor(color: model!.colors![1])
    }
    
    @IBAction func onColor3Press(_ sender: Any) {
        updateColor(color: model!.colors![2])
    }
    
    @IBAction func onColor4Press(_ sender: Any) {
        updateColor(color: model!.colors![3])
    }
    
    @IBAction func onContinueButtonPress(_ sender: UIButton) {
        arController?.setModel(model: model!)
        navigationController?.popToRootViewController(animated: true)
    }
    
    func updateDimensions() {
        width.text = String(format: "%.2f m", initialWidthScale! * model!.scale.x * getModelDimensions(modelNode!).x)
        modelNode?.scale.x = initialWidthScale! * model!.scale.x * 2
        
        height.text = String(format: "%.2f m", initialHeightScale! * model!.scale.y * getModelDimensions(modelNode!).y)
        modelNode?.scale.y = initialHeightScale! * model!.scale.y * 2
        
        depth.text = String(format: "%.2f m", initialDepthScale! * model!.scale.z * getModelDimensions(modelNode!).z)
        modelNode!.scale.z = initialDepthScale! * model!.scale.z * 2
    }
    
    func updateColor(color: String) {
        model?.color = color
        if initialMaterials.count == 0 {
            if modelNode!.geometry != nil {
                initialMaterials.append(modelNode!.geometry!.materials)
            }
            for childNode in modelNode!.childNodes {
                if childNode.geometry != nil {
                    initialMaterials.append(modelNode!.geometry!.materials)
                }
            }
            if color == "default-texture" {
                return
            }
        }
        
        if color == "default-texture" {
            var i = 0
            if modelNode!.geometry != nil {
                initialMaterials.append(modelNode!.geometry!.materials)
                modelNode!.geometry?.materials = initialMaterials[i]
                i += 1
            }
            for childNode in modelNode!.childNodes {
                if childNode.geometry != nil {
                    modelNode!.geometry?.materials = initialMaterials[i]
                    i += 1
                }
            }
        } else {
            let imageMaterial = SCNMaterial()
            imageMaterial.isDoubleSided = false
            imageMaterial.diffuse.contents = UIImage(named: color)
            if modelNode!.geometry != nil {
                modelNode!.geometry?.materials = [imageMaterial]
            }
            for childNode in modelNode!.childNodes {
                if childNode.geometry != nil {
                    childNode.geometry?.materials = [imageMaterial]
                }
            }
        }
    }
    
    func getModelDimensions(_ node: SCNNode) -> SCNVector3 {
        let (minVec, maxVec) = node.boundingBox
        let x = maxVec.x - minVec.x
        let y = maxVec.y - minVec.y
        let z = maxVec.z - minVec.z
        
        return SCNVector3(x: x, y: y, z: z)
    }
}
