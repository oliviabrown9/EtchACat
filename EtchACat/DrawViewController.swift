//
//  ViewController.swift
//  EtchACat
//
//  Created by Olivia Brown on 11/11/17.
//  Copyright © 2017 Olivia Brown. All rights reserved.
//

import UIKit

class DrawViewController: UIViewController {
    
    // UI Elements
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var drawingView: UIView!
    @IBOutlet weak var leftWheel: UIView!
    @IBOutlet weak var rightWheel: UIView!
    @IBOutlet weak var rightDot: UIView!
    @IBOutlet weak var leftDot: UIView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var closePhotoButton: UIButton!
    
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
        
        // Add border to resultImageView
        resultImageView.layer.borderColor = UIColor(red:0.75, green:0.75, blue:0.75, alpha:1.0).cgColor
        resultImageView.layer.borderWidth = 7
        
        // Submit button style
        submitButton.layer.borderColor = UIColor.white.cgColor
        submitButton.layer.borderWidth = 2.0
        submitButton.layer.cornerRadius = 20
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?){
        
        // Check if user touched a wheel
        let touch = touches.first
        var wheel: UIView? = nil
        if touch!.view == leftWheel || touch!.view == leftDot {
            wheel = leftWheel
        }
        else if touch!.view == rightWheel || touch?.view == rightDot {
            wheel = rightWheel
        }
        // Return if user did not touch a wheel
        guard let rotatedWheel = wheel else {
            return
        }
        // Rotate wheel
        let position = touch!.location(in: self.view)
        let target = rotatedWheel.center
        let angleA = atan2(target.y-(startAnglePoint?.y)!, target.x-(startAnglePoint?.x)!)
        let angleB = atan2(target.y-position.y, target.x-position.x)
        let rotationAngle = angleB - angleA
        rotatedWheel.transform = CGAffineTransform(rotationAngle: rotationAngle)
        
        // Check direction of turn
        var isClockwise: Bool = false
        if detectClockwise(radian: rotationAngle) {
            isClockwise = true
        }
        
        // Set the starting point to the center of screen for first time
        if startPoint == nil {
            startPoint = CGPoint(x: drawingView.bounds.midX, y: drawingView.bounds.midY)
        }
        // Set the end point of the line based on wheel and direction of turn
        var endPoint: CGPoint? = nil
        if wheel == leftWheel {
            if isClockwise {
                endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y - 1)
            }
            else {
                endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y + 1)
            }
        }
        else if wheel == rightWheel {
            if isClockwise {
                endPoint = CGPoint(x: startPoint!.x + 1, y: startPoint!.y)
            }
            else {
                endPoint = CGPoint(x: startPoint!.x - 1, y: startPoint!.y)
            }
        }
        else {
            return
        }
        
        // Draw line if it's within bounds & set starting point to the end of this line
        if drawingView.bounds.contains(endPoint!) {
            addLine(fromPoint: startPoint!, toPoint: endPoint!)
            startPoint = endPoint!
        }
    }
    
    // Sets initial state of startAnglePoint to be location of touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.count == 1 else {
            return
        }
        if let touch = touches.first {
            startAnglePoint = touch.location(in: view)
        }
    }

    // POSTs image of drawingView
    @IBAction func submitPressed(_ sender: Any) {
        submitButton.isHidden = true
        let drawingImage =  UIImage.init(view: drawingView!)
        let resizedImage = drawingImage.resizedForUpload()
        uploadImage(image: resizedImage!)
    }
    
    // Hides photo to allow user to continue drawing
    @IBAction func closePhotoButtonPressed(_ sender: Any) {
        resultImageView.image = nil
        resultImageView.isHidden = true
        closePhotoButton.isHidden = true
        submitButton.isHidden = false
    }
    
    // Clears the drawn lines from the screen
    private func removeLines() {
        for sublayer in drawingView.layer.sublayers! {
            if sublayer.name == "line" {
                sublayer.removeFromSuperlayer()
            }
        }
    }
    
    // Erases lines and photo on shake
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            removeLines()
            resultImageView.image = nil
            resultImageView.isHidden = false
            submitButton.isHidden = false
        }
    }
}

extension DrawViewController {
    // Draw a line between two points
    private func addLine(fromPoint start: CGPoint, toPoint end:CGPoint) {
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
        var request = URLRequest(url: URL(string: "http://13.92.99.130:7000/edges2cats_AtoB")!)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = UIImagePNGRepresentation(image)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                return
            }
            DispatchQueue.main.async {
                self.resultImageView.image = UIImage.init(data: data)
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
    fileprivate func resizedForUpload() -> UIImage? {
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
