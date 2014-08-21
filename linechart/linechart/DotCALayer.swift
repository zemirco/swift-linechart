
import UIKit
import QuartzCore

class DotCALayer: CALayer {
    
    var innerRadius: CGFloat = 8
    var dotInnerColor = UIColor.blackColor()
    
    override init() {
        super.init()
    }

    override init(layer: AnyObject!) {
        super.init(layer: layer)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        var inset = self.bounds.size.width - innerRadius
        var innerDotLayer = CALayer()
        innerDotLayer.frame = CGRectInset(self.bounds, inset/2, inset/2)
        innerDotLayer.backgroundColor = dotInnerColor.CGColor
        innerDotLayer.cornerRadius = innerRadius / 2
        self.addSublayer(innerDotLayer)
    }
    
}
