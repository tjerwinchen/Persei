// For License please refer to LICENSE file in the root of Persei project

import QuartzCore

class CircularRevealTransition: NSObject, CAAnimationDelegate {
    var completion: () -> Void = {}

    private var layer: CALayer
    private var snapshotLayer = CALayer()
    private var mask = CAShapeLayer()
    private var animation = CABasicAnimation(keyPath: "path")
    
    // MARK: - Init
    init(layer: CALayer, center: CGPoint, startRadius: CGFloat, endRadius: CGFloat) {
        self.layer = layer

        super.init()

        let startPath = CGPath(ellipseIn: CGRect(boundingCenter: center, radius: startRadius), transform: nil)
        let endPath = CGPath(ellipseIn: CGRect(boundingCenter: center, radius: endRadius), transform: nil)

        snapshotLayer.contents = layer.contents
    
        mask.path = endPath
        
        animation.duration = 0.6
        animation.fromValue = startPath
        animation.toValue = endPath
        animation.delegate = self
    }
    
    convenience init(layer: CALayer, center: CGPoint) {
        let frame = layer.frame
        
        let radius: CGFloat = {
            let x = max(center.x, frame.width - center.x)
            let y = max(center.y, frame.height - center.y)
            return sqrt(x * x + y * y)
        }()
        
        self.init(layer: layer, center: center, startRadius: 0, endRadius: radius)
    }


    func start() {
        layer.superlayer!.insertSublayer(snapshotLayer, below: layer)
        snapshotLayer.frame = layer.frame
        
        layer.mask = mask
        mask.frame = layer.bounds

        mask.add(animation, forKey: "reveal")
    }
    
    // MARK: - CAAnimationDelegate
    @objc
    internal func animationDidStop(_: CAAnimation, finished: Bool) {
        layer.mask = nil
        snapshotLayer.removeFromSuperlayer()
        
        completion()
    }
}
