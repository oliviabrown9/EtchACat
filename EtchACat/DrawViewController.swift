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
    
    @IBOutlet weak var leftWheel: UIImageView!
    @IBOutlet weak var rightWheel: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        leftWheel.isUserInteractionEnabled = true
        rightWheel.isUserInteractionEnabled = true
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?){
        let touch = touches.first
        var wheel: UIImageView = UIImageView()
        if touch!.view == leftWheel {
            wheel = leftWheel
        }
        else if touch!.view == rightWheel {
            wheel = rightWheel
        }
        
        if wheel == leftWheel || wheel == rightWheel {
            let position = touch!.location(in: self.view)
            let target = wheel.center
            let angle1 = atan2(target.y-(startPoint?.y)!, target.x-(startPoint?.x)!)
            let angle2 = atan2(target.y-position.y, target.x-position.x)
            let angle3 = angle2-angle1
            
            wheel.transform = CGAffineTransform(rotationAngle: angle3)
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
}


