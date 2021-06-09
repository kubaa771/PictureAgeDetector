//
//  ViewController.swift
//  PictureAgeDetector
//
//  Created by Jakub Iwaszek on 04/06/2021.
//

import UIKit
import CoreML
import Vision
import FaceCropper

class ViewController: UIViewController {

    @IBOutlet weak var pictureImageView: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    var presentedImage: UIImage?
    var imagePicker: UIImagePickerController!
    var numberOfPeople: Int = 0
    var numberOfChildren: Int = 0
    var numberOfAdults: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureImagePicker()
    }

    func configureImagePicker() {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
    }
    
    func resetLabel() {
        infoLabel.text = ""
        numberOfAdults = 0
        numberOfAdults = 0
        numberOfChildren = 0
    }

    @IBAction func takePhotoButtonTouched(_ sender: UIButton) {
        resetLabel()
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func choosePhotoButtonTouched(_ sender: UIButton) {
        resetLabel()
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func detectFacesButtonTouched(_ sender: UIButton) {
        guard let image = presentedImage else {
            self.showAlert(title: "Alert", message: "Choose a correct image.")
            return
        }
        detectFaces(image: image)
    }
    
    func detectFaces(image: UIImage) {
        image.face.crop { (result) in
            switch result {
            case .success(let faces):
                self.numberOfPeople = faces.count
                self.infoLabel.text = "Numer of faces: \(faces.count)"
                for face in faces {
                    self.detectAge(image: face.cgImage!)
                }
            case .notFound:
                self.infoLabel.text = "No faces detected."
            case .failure(let error):
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    func detectAge(image: CGImage) {
        guard let model = try? VNCoreMLModel(for: AgeNet().model) else {
            self.showAlert(title: "Error", message: "Model couldn't be loaded")
            return
        }
        
        let request = VNCoreMLRequest(model: model) { (req, error) in
            guard error == nil else {
                self.showAlert(title: "Error", message: error!.localizedDescription)
                return
            }
            
            DispatchQueue.main.async {
                if let results = req.results as? [VNClassificationObservation] {
                    let first = results.first
                    guard let agesString = first?.identifier else { return }
                    let firstAgeDetection = agesString.split(separator: "-")[0]
                    print(firstAgeDetection)
                    guard let firstAge = Int(firstAgeDetection) else { return }
                    if firstAge < 20 {
                        self.numberOfChildren += 1
                    } else {
                        self.numberOfAdults += 1
                    }
                    self.infoLabel.text = "Number of people: \(self.numberOfPeople)\nNumber of children: \(self.numberOfChildren)\nNumber of adults: \(self.numberOfAdults)"
                }
            }
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            let handler = VNImageRequestHandler(cgImage: image, orientation: self.convertImageOrientation(orientation: self.presentedImage!.imageOrientation))
            do {
                try handler.perform([request])
            } catch let requestError{
                self.showAlert(title: "Error", message: requestError.localizedDescription)
            }
        }
    }
    
    func convertImageOrientation(orientation: UIImage.Orientation) -> CGImagePropertyOrientation  {
        let cgiOrientations: [CGImagePropertyOrientation] = [
            .up, .down, .left, .right, .upMirrored, .downMirrored, .leftMirrored, .rightMirrored
        ]

        return cgiOrientations[orientation.rawValue]
    }
    
    
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        guard let image = info[.originalImage] as? UIImage else {
            self.showAlert(title: "Error", message: "Image not found.")
            return
        }
        presentedImage = image
        pictureImageView.image = image
    }
}


extension UIViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAlertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAlertAction)
        self.present(alert, animated: true, completion: nil)
    }
}


