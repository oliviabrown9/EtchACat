//
//  ViewController.swift
//  EtchACat
//
//  Created by Olivia Brown on 11/11/17.
//  Copyright © 2017 Olivia Brown. All rights reserved.
//

import UIKit

class DrawViewController: UIViewController {
    
    // IBOutlets
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var drawingView: UIView!
    @IBOutlet weak var leftWheel: UIView!
    @IBOutlet weak var rightWheel: UIView!
    @IBOutlet weak var rightDot: UIView!
    @IBOutlet weak var leftDot: UIView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var closePhotoButton: UIButton!
    @IBOutlet weak var randomButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var dogOrCatLabel: UILabel!
    
    // Class constants
    let grayColor = UIColor(red:0.75, green:0.75, blue:0.75, alpha:1.0)
    
    // Class variables
    var startAnglePoint: CGPoint?
    var startPoint: CGPoint? = nil
    var angleLast: CGFloat =  0.0
    
    // Setting up the UI
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // Make wheels & dots into circles
        leftWheel.makeCircular()
        rightWheel.makeCircular()
        leftDot.makeCircular()
        rightDot.makeCircular()
        
        // Add shadows
        leftWheel.addShadow(radius: 4)
        rightWheel.addShadow(radius: 4)
        drawingView.addShadow(radius: 50)
        resultImageView.addShadow(radius: 50)
        
        // Submit button style
        submitButton.layer.borderColor = UIColor.white.cgColor
        submitButton.layer.borderWidth = 2.0
        submitButton.layer.cornerRadius = 20
        
        // Random button style
        randomButton.layer.borderColor = UIColor.white.cgColor
        randomButton.layer.borderWidth = 2.0
        randomButton.layer.cornerRadius = 20
    }
    
    var lastPoint: CGPoint? = nil
    var firstTime = true
    
    // Sets initial state of startAnglePoint to be location of touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.count == 1 else {
            return
        }
        if let touch = touches.first {
            if touch.view == leftWheel || touch.view == rightWheel || touch.view == leftDot || touch.view == rightDot {
                if firstTime {
                    startAnglePoint = touch.location(in: view)
                    firstTime = false
                }
            }
            else if touch.view == drawingView {
                lastPoint = touch.location(in: drawingView)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?){
        
        guard let touch = touches.first else {
            return
        }
        var wheel: UIView? = nil
        if touch.view == leftWheel || touch.view == leftDot {
            wheel = leftWheel
        }
        else if touch.view == rightWheel || touch.view == rightDot {
            wheel = rightWheel
        }
        if let touchedWheel = wheel {
            rotateWheel(touch: touch, wheel: touchedWheel)
            
            if startPoint == nil {
                startPoint = CGPoint(x: drawingView.bounds.midX, y: drawingView.bounds.midY)
            }
            let endPoint: CGPoint? = setEndPoint(wheel: touchedWheel)
            
            if drawingView.bounds.contains(endPoint!) {
                addLine(fromPoint: startPoint!, toPoint: endPoint!)
                startPoint = endPoint!
            }
        }
        else if touch.view == drawingView {
            if lastPoint == nil {
                lastPoint = touch.location(in: drawingView)
                return
            }
            let currentPoint = touch.location(in: drawingView)
            addLine(fromPoint: lastPoint!, toPoint: currentPoint)
            lastPoint = currentPoint
        }
    }
    
    private func rotateWheel(touch: UITouch, wheel: UIView) {
        let position = touch.location(in: self.view)
        let target = wheel.center
        let angleA = atan2(target.y-(startAnglePoint?.y)!, target.x-(startAnglePoint?.x)!)
        let angleB = atan2(target.y-position.y, target.x-position.x)
        let rotationAngle = angleB - angleA
        wheel.transform = CGAffineTransform(rotationAngle: rotationAngle)
    }
    
    private func setEndPoint(wheel: UIView) -> CGPoint? {
        let rotationAngle = atan2f(Float(wheel.transform.b), Float(wheel.transform.a))
        let isClockwise: Bool = detectClockwise(radian: CGFloat(rotationAngle))
        
        if wheel == leftWheel {
            if isClockwise {
                return CGPoint(x: startPoint!.x, y: startPoint!.y - 1)
            }
            else {
                return CGPoint(x: startPoint!.x, y: startPoint!.y + 1)
            }
        }
        else if wheel == rightWheel {
            if isClockwise {
                return CGPoint(x: startPoint!.x + 1, y: startPoint!.y)
            }
            else {
                return CGPoint(x: startPoint!.x - 1, y: startPoint!.y)
            }
        }
        return nil
    }
    
    // Clears the drawn lines from the screen
    private func removeLines() {
        guard let sublayers = drawingView.layer.sublayers else {
            return
        }
        for sublayer in sublayers {
            if sublayer.name == "line" {
                sublayer.removeFromSuperlayer()
            }
        }
    }
    
    // Erases on shake
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            removeLines()
            resultImageView.image = nil
            resultImageView.isHidden = false
            submitButton.isHidden = false
            removeRandom()
        }
    }
    
    // POSTs image of drawingView
    @IBAction func submitPressed(_ sender: Any) {
        activityIndicator.startAnimating()
        clearButton.isHidden = true
        randomButton.isHidden = true
        let drawingImage =  UIImage.init(view: drawingView!)
        let resizedImage = drawingImage.resizeForUpload()
        uploadImage(image: resizedImage!)
    }
    
    private func removeRandom() {
        for subview in drawingView.subviews {
            if subview.tag == 1000 {
                subview.removeFromSuperview()
            }
        }
    }
    
    // Hides photo to allow user to continue drawing
    @IBAction func closePhotoButtonPressed(_ sender: Any) {
        resultImageView.image = nil
        resultImageView.isHidden = true
        dogOrCatLabel.isHidden = true
        closePhotoButton.isHidden = true
        clearButton.isHidden = false
        submitButton.isHidden = false
        removeLines()
        removeRandom()
        randomButton.isHidden = false
    }
    
    @IBAction func clearButtonPressed(_ sender: Any) {
        removeLines()
        removeRandom()
        randomButton.isHidden = false
    }
    
    @IBAction func randomButtonPressed(_ sender: Any) {
        removeLines()
        removeRandom()

        var possibleImages: [String] = ["cats1", "cats2", "cats3", "cats4", "cats5", "dogs1", "dogs2", "dogs3", "dogs4", "dogs5"]
        let random = Int(arc4random_uniform(UInt32(possibleImages.count)))
        let randomImageName = possibleImages[random]
        let image = UIImage(named: randomImageName)
        let imageView = UIImageView(image: image!)
        imageView.frame = CGRect(x: drawingView.bounds.minX, y: drawingView.bounds.minY, width: drawingView.frame.width, height: drawingView.frame.height)
        imageView.tag = 1000
        drawingView.addSubview(imageView)
    }
}

extension DrawViewController {
    // Draw a line between two points
    private func addLine(fromPoint start: CGPoint, toPoint end: CGPoint) {
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: start)
        linePath.addLine(to: end)
        line.path = linePath.cgPath
        line.strokeColor = UIColor.black.cgColor
        line.lineWidth = 1
        line.name = "line"
        line.lineJoin = kCALineJoinRound
        self.drawingView.layer.addSublayer(line)
    }
    
    // Convert radians to degrees for turn direction calculation
    private func convertRadianToDegree(angle: CGFloat) -> CGFloat {
        var bearingDegrees = angle * (180 / .pi)
        if bearingDegrees > 0.0 {
        } else {
            bearingDegrees =  bearingDegrees + 360
        }
        return CGFloat(bearingDegrees)
    }
    
    // Checks the direction a wheel is spinning (true if clockwise & false if counterclockwise)
    private func detectClockwise(radian: CGFloat) -> Bool {
        var degree = self.convertRadianToDegree(angle: radian)
        degree = degree + 0.5
        
        // Handles moving too quickly on clockwise turn
        if angleLast > 300.0 && degree < 50 {
            angleLast = 0.0
        }
        
        // Handles moving too quickly on counterclockwise turn
        if angleLast < 100  && degree > 300 {
            angleLast = degree + 1
        }
        
        if angleLast <= degree  {
            angleLast = degree
            return true
        }
        else {
            angleLast = degree
            return false
        }
    }
    
    // POSTing image to API, turning the returned data into an image, and displaying the result
    private func uploadImage(image: UIImage) {
        var request = URLRequest(url: URL(string: "http://13.92.99.130:7000/")!)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = UIImagePNGRepresentation(image)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                return
            }
            
            var animalType: String? = nil
            if let httpStatus = response as? HTTPURLResponse {
                let headerDict = httpStatus.allHeaderFields
                animalType = headerDict["predicted_class"] as? String
            }
            
            guard let type = animalType else {
                return
            }
            
            DispatchQueue.main.async {
                if type == "cat" {
                    self.dogOrCatLabel.text = "It's a cat!"
                }
                else if type == "dog" {
                    self.dogOrCatLabel.text = "It's a dog!"
                }
                
                self.submitButton.isHidden = true
                self.dogOrCatLabel.isHidden = false
                self.resultImageView.image = UIImage.init(data: data)
                self.activityIndicator.stopAnimating()
                self.resultImageView.isHidden = false
                self.closePhotoButton.isHidden = false
            }
        }
        task.resume()
    }
    
    // Hide the status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension UIImage {
    // Convert UIView to UIImage
    convenience init(view: UIView) {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()
        self.init(cgImage: (image!))
    }
    
    // Resizing the image to be compatible with the API
    fileprivate func resizeForUpload() -> UIImage? {
        let canvasSize = CGSize(width: 256.0, height: 256.0)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

extension UIView {
    // Adds a light shadow to a view
    func addShadow(radius: CGFloat) {
        self.layer.shadowOffset = CGSize.zero
        self.layer.shadowRadius = radius
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.3
    }
    
    // Makes a view a circle
    func makeCircular() {
        self.layer.cornerRadius = self.frame.size.width/2.0
    }
}
