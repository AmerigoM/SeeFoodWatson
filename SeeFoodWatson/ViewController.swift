//
//  ViewController.swift
//  SeeFoodWatson
//
//  Created by Amerigo Mancino on 14/09/2019.
//  Copyright © 2019 Amerigo Mancino. All rights reserved.
//

import UIKit
import VisualRecognitionV3
import SVProgressHUD

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var topBarImageView: UIImageView!
    @IBOutlet weak var shareButton: UIButton!
    
    let apiKey = "On8cJ4T8YdHkPqPYgMeM11KQ6uxQWjBmoB3zbXRhtHBA"
    let version = "2019-09-14"
    
    let imagePicker = UIImagePickerController()
    var classificationResults: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shareButton.isHidden = true
        imagePicker.delegate = self
    }
    
    // tells the deleagte that the user picked a still image or a movie
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // disable the camera button
        cameraButton.isEnabled = false
        
        // start a spinner
        SVProgressHUD.show()
        
        if let image = info[.originalImage] as? UIImage {
            imageView.image = image
            imagePicker.dismiss(animated: true, completion: nil)
            
            // setup the visual recognition engine
            let visualRecognition = VisualRecognition(version: version, apiKey: apiKey)

            // compress the image picked to 1% of its original size
            // since we don't want to send 30 GB of data to Bluemix
            guard let smallImage = image.resized(withPercentage: 0.1)
                else {
                    fatalError("Couldn't create small image")
            }
            
            visualRecognition.classify(image: smallImage) { (response, error) in
                if let error = error {
                    print(error)
                }
                
                guard let classifiedImages = response?.result else {
                    print("Failed to classify the image")
                    return
                }
                
                // here the classified images can be accessed
                let classes = classifiedImages.images.first!.classifiers.first!.classes
            
                self.classificationResults = []
                for index in 0..<classes.count {
                    self.classificationResults.append(classes[index].className)
                }
                
                // print(self.classificationResults)
                
                // re-enable the camera button and dismiss the spinner
                DispatchQueue.main.async {
                    self.cameraButton.isEnabled = true
                    SVProgressHUD.dismiss()
                    self.shareButton.isHidden = false
                }
                
                if(self.classificationResults.contains("pizza")) {
                    DispatchQueue.main.async {
                        self.navigationItem.title = "Pizza!"
                        self.navigationController?.navigationBar.barTintColor = UIColor.green
                        self.navigationController?.navigationBar.isTranslucent = false
                        self.topBarImageView.image = UIImage(named: "hotdog")
                    }
                } else {
                    DispatchQueue.main.async {
                        self.navigationItem.title = "Not pizza!"
                        self.navigationController?.navigationBar.barTintColor = UIColor.red
                        self.navigationController?.navigationBar.isTranslucent = false
                        self.topBarImageView.image = UIImage(named: "not-hotdog")
                    }
                }
            }
        } else {
            print("There was an error picking the image")
        }
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        // type of picker interface to be displayed by the controller
        imagePicker.sourceType = .camera
        // the user is not allowed to edit the image after it's picked
        imagePicker.allowsEditing = false
        // present the imagePicker
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func shareTapped(_ sender: UIButton) {
        
    }
}

/*
 * Estension that handles resizing
 */
extension UIImage {
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvas = CGSize(width: size.width * percentage, height: size.height * percentage)
        return UIGraphicsImageRenderer(size: canvas, format: imageRendererFormat).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvas = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        return UIGraphicsImageRenderer(size: canvas, format: imageRendererFormat).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
}
