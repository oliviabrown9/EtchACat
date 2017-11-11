//
//  ViewController.swift
//  EtchACat
//
//  Created by Olivia Brown on 11/11/17.
//  Copyright © 2017 Olivia Brown. All rights reserved.
//

import UIKit
import Alamofire

class DrawViewController: UIViewController {
    
    var startAnglePoint: CGPoint?
    
    @IBOutlet weak var leftWheel: UIImageView!
    @IBOutlet weak var rightWheel: UIImageView!
    
    @IBOutlet weak var drawingImageView: UIImageView!
    
    var startPoint: CGPoint? = nil
    var angleLast: CGFloat =  0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        leftWheel.isUserInteractionEnabled = true
        rightWheel.isUserInteractionEnabled = true
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?){
        let touch = touches.first
        
        // check if user touched a wheel
        var wheel: UIImageView? = nil
        if touch!.view == leftWheel {
            wheel = leftWheel
        }
        else if touch!.view == rightWheel {
            wheel = rightWheel
        }
        // return if user did not touch a wheel
        guard let rotatedWheel = wheel else {
            return
        }
        
        // rotate wheel
        let position = touch!.location(in: self.view)
        let target = rotatedWheel.center
        let angleA = atan2(target.y-(startAnglePoint?.y)!, target.x-(startAnglePoint?.x)!)
        let angleB = atan2(target.y-position.y, target.x-position.x)
        let angleC = angleB-angleA
        rotatedWheel.transform = CGAffineTransform(rotationAngle: angleC)
        
        // check clockwise
        let angle = atan2f(Float(rotatedWheel.transform.b), Float(rotatedWheel.transform.a));
        var isClockwise: Bool = false
        if detectClockwise(radian: CGFloat(angle)) {
            isClockwise = true
        }
        
        // set end point of line
        if startPoint == nil {
            startPoint = CGPoint(x: view.frame.midX, y: view.frame.midY)
        }
        var endPoint: CGPoint? = nil
        if wheel == leftWheel && isClockwise {
            endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y - 5)
        }
        else if wheel == leftWheel && !isClockwise {
            endPoint = CGPoint(x: startPoint!.x, y: startPoint!.y + 5)
        }
        else if wheel == rightWheel && isClockwise {
            endPoint = CGPoint(x: startPoint!.x + 5, y: startPoint!.y)
        }
        else if wheel == rightWheel && !isClockwise {
            endPoint = CGPoint(x: startPoint!.x - 5, y: startPoint!.y)
        }
        else {
            print("end point")
            return // idk if necessary
        }
        addLine(fromPoint: startPoint!, toPoint: endPoint!)
        startPoint = endPoint!
        // draw very small line from last point to a slightly larger point
        // store end point as the "to" value of the line above
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.count == 1 else {
            return
        }
        if let touch = touches.first {
            startAnglePoint = touch.location(in: view)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        angleLast = 0
    }
    
    @IBAction func submitPressed(_ sender: Any) {
        uploadImage()
    }

}

extension DrawViewController {
    
    func addLine(fromPoint start: CGPoint, toPoint end:CGPoint) {
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: start)
        linePath.addLine(to: end)
        line.path = linePath.cgPath
        line.strokeColor = UIColor.red.cgColor
        line.lineWidth = 1
        line.lineJoin = kCALineJoinRound
        print("add line")
        self.view.layer.addSublayer(line)
    }
    
    func convertRadianToDegree(angle: CGFloat) -> CGFloat {
        var bearingDegrees = angle * (180 / .pi)
        if bearingDegrees > 0.0 {
            
        } else {
            bearingDegrees =  bearingDegrees + 360
        }
        return CGFloat(bearingDegrees)
    }
    
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
        } else {
            angleLast = degree
            returnData = false
        }
        
        return returnData
    }
    
    // POSTing image to API
    func uploadImage() {
        let imageData = UIImagePNGRepresentation(#imageLiteral(resourceName: "testImage")) // throwing in test image
        let requestURLString = "https://cors-anywhere.herokuapp.com/https://pix2pix.affinelayer.com/edges2cats_AtoB"
        
        Alamofire.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(imageData!, withName: "testImage", fileName: "testImage.png", mimeType: "image/png")
        },
                         to:requestURLString)
        { (result) in
            switch result {
            case .success(let upload, _, _):
                
                upload.uploadProgress(closure: { (progress) in
                    print("Upload Progress: \(progress.fractionCompleted)")
                })
                
                upload.responseJSON { response in
                    print(response.result.value as Any)
                }
                
            case .failure(let encodingError):
                print(encodingError)
            }
        }
    }
    
    
}
