//
//  ViewController.swift
//  EtchACat
//
//  Created by Olivia Brown on 11/11/17.
//  Copyright © 2017 Olivia Brown. All rights reserved.
//

import UIKit

class DrawViewController: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Make wheels & dots into circles
        leftWheel.makeCircular()
        rightWheel.makeCircular()
        leftDot.makeCircular()
        rightDot.makeCircular()
        
        // Add shadows
        leftWheel.addShadow()
        rightWheel.addShadow()
        
        // Add corner radii
        drawingView.layer.cornerRadius = 10
        resultImageView.layer.cornerRadius = 10
        
        // Submit button style
        submitButton.layer.borderColor = UIColor.white.cgColor
        submitButton.layer.borderWidth = 2.0
        submitButton.layer.cornerRadius = 20
    }
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?){
        
        let touch = touches.first
        
        // Check if user touched a wheel
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
        
        // rotate wheel
        let position = touch!.location(in: self.view)
        let target = rotatedWheel.center
        let angleA = atan2(target.y-(startAnglePoint?.y)!, target.x-(startAnglePoint?.x)!)
        let angleB = atan2(target.y-position.y, target.x-position.x)
        rotatedWheel.transform = CGAffineTransform(rotationAngle: angleB-angleA)
        
        // Check direction of turn
        let angle = atan2f(Float(rotatedWheel.transform.b), Float(rotatedWheel.transform.a));
        var isClockwise: Bool = false
        if detectClockwise(radian: CGFloat(angle)) {
            isClockwise = true
        }
        
        // Set the starting point to the center of screen for first time
        if startPoint == nil {
            startPoint = CGPoint(x: drawingView.bounds.midX, y: drawingView.bounds.midY)
        }
        // Set the end point of the line based on wheel and direction of turn
        var endPoint: CGPoint? = nil
        if wheel == leftWheel && isClockwise {
            endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y - 1)
        }
        else if wheel == leftWheel && !isClockwise {
            endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y + 1)
        }
        else if wheel == rightWheel && isClockwise {
            endPoint = CGPoint(x: startPoint!.x + 1, y: startPoint!.y)
        }
        else if wheel == rightWheel && !isClockwise {
            endPoint = CGPoint(x: startPoint!.x - 1, y: startPoint!.y)
        }
        else {
            return
        }
        
        // Draw line if it's within bounds & set starting point of next line to the end of this line
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
    
    // Resets angleLast for next touch
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        angleLast = 0
    }
    
    // Captures an image of the drawing and POSTs to server
    @IBAction func submitPressed(_ sender: Any) {
        submitButton.isHidden = true
        let drawingImage =  UIImage.init(view: drawingView)
        let resizedImage = drawingImage.resized(toWidth: 256.0)
        let invertedImage = resizedImage?.invertColofOfImage()
        resultImageView.isHidden = false
        resultImageView.image = invertedImage
//        uploadImage(image: invertedImage!)
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
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            removeLines()
            resultImageView.image = nil
            resultImageView.isHidden = false
            submitButton.isHidden = false
        }
    }
}

extension DrawViewController {
    // Draw a line between two points with an identifying name
    func addLine(fromPoint start: CGPoint, toPoint end:CGPoint) {
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
    func convertRadianToDegree(angle: CGFloat) -> CGFloat {
        var bearingDegrees = angle * (180 / .pi)
        if bearingDegrees > 0.0 {
        } else {
            bearingDegrees =  bearingDegrees + 360
        }
        return CGFloat(bearingDegrees)
    }
    
    // Checks the direction a wheel is spinning (true if clockwise; false if counterclockwise)
    func detectClockwise(radian: CGFloat) -> Bool {
        var degree = self.convertRadianToDegree(angle: radian)
        degree = degree + 0.5
        
        // Handles moving too fast following clockwise turn
        if angleLast > 300.0 && degree < 50 {
            angleLast = 0.0
        }
        
        // Handles moving too fast following counterclockwise turn
        if angleLast < 100  && degree > 300 {
            angleLast = degree + 1
        }
        
        var returnData = false
        if angleLast <= degree  {
            angleLast = degree
            returnData = true
        }
        else {
            angleLast = degree
            returnData = false
        }
        return returnData
    }
    
    // POSTing image to API, turning the returned data into an image, and displaying the result
    private func uploadImage(image: UIImage) {
        let imageData = UIImagePNGRepresentation(image)
        let url = URL(string: "http://13.92.99.130:7000/edges2handbags_AtoB")!
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = imageData
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                return
            }
            DispatchQueue.main.async {
                let newImage = UIImage.init(data: data)
                self.resultImageView.isHidden = false
                self.resultImageView.image = newImage
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
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: (image?.cgImage)!)
    }
    
    // Resizing the image to be compatible with the API
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: width)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func invertColofOfImage() -> UIImage {
        var image = self
        let context = CIContext(options: nil)
        
        if let currentFilter = CIFilter(name: "CIColorInvert") {
            let beginImage = CIImage(image: image)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            
            if let output = currentFilter.outputImage {
                if let cgimg = context.createCGImage(output, from: output.extent) {
                    image = UIImage(cgImage: cgimg)
                    print("working!")
                    return image
                }
            }
        }
        return image
    }
}

extension UIView {
    // Adds a light shadow to a view
    func addShadow() {
        self.layer.shadowOffset = CGSize.zero
        self.layer.shadowRadius = 4
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.3
    }
    
    // Makes a view a perfect circle
    func makeCircular() {
        self.layer.cornerRadius = self.frame.size.width/2.0
    }
}
