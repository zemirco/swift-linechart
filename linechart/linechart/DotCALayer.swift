
import UIKit
import QuartzCore

class DotCALayer: CALayer {
    
    var innerRadius: CGFloat = 8
    var dotInnerColor = UIColor.blackColor()
    
    init() {
        super.init()
    }
    
    init(layer: AnyObject!) {
        super.init(layer: layer)
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
