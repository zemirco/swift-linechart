
import UIKit
import QuartzCore

class DotCALayer: CALayer {
    
    var dotBorderWith: CGFloat = 4
    var dotInnerColor = UIColor.blackColor()
   
    init() {
        super.init()
    }
    
    init(layer: AnyObject!) {
        super.init(layer: layer)
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        
        // add inner dot
        var outerDotLayerWidth = self.bounds.size.width
        var innerDotLayerWidth = outerDotLayerWidth - dotBorderWith
    
        var innerDotLayer = CALayer()
        innerDotLayer.backgroundColor = dotInnerColor.CGColor
        innerDotLayer.cornerRadius = innerDotLayerWidth / 2
        innerDotLayer.frame = CGRect(x: dotBorderWith/2, y: dotBorderWith/2, width: innerDotLayerWidth, height: innerDotLayerWidth)
        
        self.addSublayer(innerDotLayer)
    }
    
}
