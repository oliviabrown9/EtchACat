//
//  ViewController.swift
//  EtchACat
//
//  Created by Olivia Brown on 11/11/17.
//  Copyright © 2017 Olivia Brown. All rights reserved.
//

import UIKit

class DrawViewController: UIViewController {
    
    var startPoint: CGPoint?
    @IBOutlet weak var lblLabel: UILabel!
    
    @IBOutlet weak var leftWheel: UIImageView!
    @IBOutlet weak var rightWheel: UIImageView!
    
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
        let angle1 = atan2(target.y-(startPoint?.y)!, target.x-(startPoint?.x)!)
        let angle2 = atan2(target.y-position.y, target.x-position.x)
        let angle3 = angle2-angle1
        
        rotatedWheel.transform = CGAffineTransform(rotationAngle: angle3)
        
        let angle = atan2f(Float(rotatedWheel.transform.b), Float(rotatedWheel.transform.a));
        if detectClockwise(radian: CGFloat(angle)) {
            print("Clockwise")
        } else {
            print("Counterclockwise")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.count == 1 else {
            return
        }
        if let touch = touches.first {
            startPoint = touch.location(in: view)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        angleLast = 0
    }
}

extension DrawViewController {
    
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
        
        // moving too fast following clockwise
        if angleLast > 300.0 && degree < 50 {
            angleLast = 0.0
        }
        
        //moving too fast following anti-clockwise
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
}

extension DrawViewController {
    func radionToDegree(_ radian: CGFloat) -> CGFloat {
        return radian * (180 / .pi)
    }
}


