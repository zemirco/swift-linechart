


import UIKit
import QuartzCore



/**
 * Helpers class
 */
private class Helpers {
    
    /**
     * Convert hex color to UIColor
     */
    private class func UIColorFromHex(hex: Int) -> UIColor {
        var red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        var green = CGFloat((hex & 0xFF00) >> 8) / 255.0
        var blue = CGFloat((hex & 0xFF)) / 255.0
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
    
    /**
     * Lighten color.
     */
    private class func lightenUIColor(color: UIColor) -> UIColor {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: b * 1.5, alpha: a)
    }
}



// delegate method
public protocol LineChartDelegate {
    func didSelectDataPoint(x: CGFloat, yValues: [CGFloat])
}

public struct Animation {
    public var enabled: Bool = true
    public var duration: CFTimeInterval = 1
}

public struct Labels {
    public var x: Bool = true
    public var y: Bool = true
}

public struct Grid {
    public var visible: Bool = true
    public var x: CGFloat = 10
    public var y: CGFloat = 10
    // #eeeeee
    public var color: UIColor = UIColor(red: 238/255.0, green: 238/255.0, blue: 238/255.0, alpha: 1)
}

public struct Dots {
    public var visible: Bool = true
    public var color: UIColor = UIColor.whiteColor()
    public var innerRadius: CGFloat = 8
    public var outerRadius: CGFloat = 12
    public var innerRadiusHighlighted: CGFloat = 8
    public var outerRadiusHighlighted: CGFloat = 12
}

public struct Axes {
    public var visible: Bool = true
    // #607d8b
    public var color: UIColor = UIColor(red: 96/255.0, green: 125/255.0, blue: 139/255.0, alpha: 1)
    public var inset: CGFloat = 15
}



/**
 * LineChart
 */
public class LineChart: UIView {
    
    // default configuration
    public var labels: Labels = Labels()
    public var area: Bool = true
    public var grid: Grid = Grid()
    public var animation: Animation = Animation()
    public var dots: Dots = Dots()
    public var axes: Axes = Axes()
    public var removeAll: Bool = false
    public var lineWidth: CGFloat = 2
    
    private var xScale: ((CGFloat) -> CGFloat)!
    private var xInvert: ((CGFloat) -> CGFloat)!
    private var xTicks: (CGFloat, CGFloat, CGFloat)!
    
    private var yScale: ((CGFloat) -> CGFloat)!
    private var yTicks: (CGFloat, CGFloat, CGFloat)!

    
    // values calculated on init
    private var drawingHeight: CGFloat = 0 {
        didSet {
            var max = getMaximumValue()
            var min = getMinimumValue()
            var scale = LinearScale(domain: [min, max], range: [0, drawingHeight])
            yScale = scale.scale()
            yTicks = scale.ticks(10)
        }
    }
    private var drawingWidth: CGFloat = 0 {
        didSet {
            var data = dataStore[0]
            var scale = LinearScale(domain: [0.0, CGFloat(count(data) - 1)], range: [0, drawingWidth])
            xScale = scale.scale()
            xInvert = scale.invert()
            xTicks = scale.ticks(10)
        }
    }
    
    public var delegate: LineChartDelegate?
    
    // data stores
    private var dataStore: [[CGFloat]] = []
    private var dotsDataStore: [[DotCALayer]] = []
    private var lineLayerStore: [CAShapeLayer] = []
    
    // category10 colors from d3 - https://github.com/mbostock/d3/wiki/Ordinal-Scales
    public var colors: [UIColor] = [
        UIColor(red: 0.121569, green: 0.466667, blue: 0.705882, alpha: 1),
        UIColor(red: 1, green: 0.498039, blue: 0.054902, alpha: 1),
        UIColor(red: 0.172549, green: 0.627451, blue: 0.172549, alpha: 1),
        UIColor(red: 0.839216, green: 0.152941, blue: 0.156863, alpha: 1),
        UIColor(red: 0.580392, green: 0.403922, blue: 0.741176, alpha: 1),
        UIColor(red: 0.54902, green: 0.337255, blue: 0.294118, alpha: 1),
        UIColor(red: 0.890196, green: 0.466667, blue: 0.760784, alpha: 1),
        UIColor(red: 0.498039, green: 0.498039, blue: 0.498039, alpha: 1),
        UIColor(red: 0.737255, green: 0.741176, blue: 0.133333, alpha: 1),
        UIColor(red: 0.0901961, green: 0.745098, blue: 0.811765, alpha: 1)
    ]
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
    }

    convenience override init() {
        self.init(frame: CGRectZero)
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func drawRect(rect: CGRect) {
        
        if removeAll {
            var context = UIGraphicsGetCurrentContext()
            CGContextClearRect(context, rect)
            return
        }
        
        self.drawingHeight = self.bounds.height - (2 * axes.inset)
        self.drawingWidth = self.bounds.width - (2 * axes.inset)
        
        // remove all labels
        for view: AnyObject in self.subviews {
            view.removeFromSuperview()
        }
        
        // remove all lines on device rotation
        for lineLayer in lineLayerStore {
            lineLayer.removeFromSuperlayer()
        }
        lineLayerStore.removeAll()
        
        // remove all dots on device rotation
        for dotsData in dotsDataStore {
            for dot in dotsData {
                dot.removeFromSuperlayer()
            }
        }
        dotsDataStore.removeAll()
        
        // draw grid
        if grid.visible { drawGrid() }
        
        // draw axes
        if axes.visible { drawAxes() }
        
        // draw labels
        if labels.x { drawXLabels() }
        if labels.y { drawYLabels() }
        
        // draw lines
        for (lineIndex, lineData) in enumerate(dataStore) {
            
            drawLine(lineIndex)
            
            // draw dots
            if dots.visible { drawDataDots(lineIndex) }
            
            // draw area under line chart
            if area { drawAreaBeneathLineChart(lineIndex) }
            
        }
        
    }
    
    
    
    /**
     * Get y value for given x value. Or return zero or maximum value.
     */
    private func getYValuesForXValue(x: Int) -> [CGFloat] {
        var result: [CGFloat] = []
        for lineData in dataStore {
            if x < 0 {
                result.append(lineData[0])
            } else if x > lineData.count - 1 {
                result.append(lineData[lineData.count - 1])
            } else {
                result.append(lineData[x])
            }
        }
        return result
    }
    
    
    
    /**
     * Handle touch events.
     */
    private func handleTouchEvents(touches: NSSet!, event: UIEvent) {
        if (self.dataStore.isEmpty) {
            return
        }
        var point: AnyObject! = touches.anyObject()
        var xValue = point.locationInView(self).x
        var inverted = self.xInvert(xValue - axes.inset)
        var rounded = Int(round(Double(inverted)))
        var yValues: [CGFloat] = getYValuesForXValue(rounded)
        highlightDataPoints(rounded)
        delegate?.didSelectDataPoint(CGFloat(rounded), yValues: yValues)
    }
    
    
    
    /**
     * Listen on touch end event.
     */
    override public func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        handleTouchEvents(touches, event: event)
    }
    
    
    
    /**
     * Listen on touch move event
     */
    override public func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        handleTouchEvents(touches, event: event)
    }
    
    
    
    /**
     * Highlight data points at index.
     */
    private func highlightDataPoints(index: Int) {
        for (lineIndex, dotsData) in enumerate(dotsDataStore) {
            // make all dots white again
            for dot in dotsData {
                dot.backgroundColor = dots.color.CGColor
            }
            // highlight current data point
            var dot: DotCALayer
            if index < 0 {
                dot = dotsData[0]
            } else if index > dotsData.count - 1 {
                dot = dotsData[dotsData.count - 1]
            } else {
                dot = dotsData[index]
            }
            dot.backgroundColor = Helpers.lightenUIColor(colors[lineIndex]).CGColor
        }
    }
    
    
    
    /**
     * Draw small dot at every data point.
     */
    private func drawDataDots(lineIndex: Int) {
        var dotLayers: [DotCALayer] = []
        var data = self.dataStore[lineIndex]
        
        for index in 0..<data.count {
            var xValue = self.xScale(CGFloat(index)) + axes.inset - dots.outerRadius/2
            var yValue = self.bounds.height - self.yScale(data[index]) - axes.inset - dots.outerRadius/2
            
            // draw custom layer with another layer in the center
            var dotLayer = DotCALayer()
            dotLayer.dotInnerColor = colors[lineIndex]
            dotLayer.innerRadius = dots.innerRadius
            dotLayer.backgroundColor = dots.color.CGColor
            dotLayer.cornerRadius = dots.outerRadius / 2
            dotLayer.frame = CGRect(x: xValue, y: yValue, width: dots.outerRadius, height: dots.outerRadius)
            self.layer.addSublayer(dotLayer)
            dotLayers.append(dotLayer)
            
            // animate opacity
            if animation.enabled {
                var anim = CABasicAnimation(keyPath: "opacity")
                anim.duration = animation.duration
                anim.fromValue = 0
                anim.toValue = 1
                dotLayer.addAnimation(anim, forKey: "opacity")
            }
            
        }
        dotsDataStore.append(dotLayers)
    }
    
    
    
    /**
     * Draw x and y axis.
     */
    private func drawAxes() {
        var height = self.bounds.height
        var width = self.bounds.width
        var path = UIBezierPath()
        axes.color.setStroke()
        // draw x-axis
        var y0 = height - self.yScale(0) - axes.inset
        path.moveToPoint(CGPoint(x: axes.inset, y: y0))
        path.addLineToPoint(CGPoint(x: width - axes.inset, y: y0))
        path.stroke()
        // draw y-axis
        path.moveToPoint(CGPoint(x: axes.inset, y: height - axes.inset))
        path.addLineToPoint(CGPoint(x: axes.inset, y: axes.inset))
        path.stroke()
    }
    
    
    
    /**
     * Get maximum value in all arrays in data store.
     */
    private func getMaximumValue() -> CGFloat {
        var max: CGFloat = 1
        for data in dataStore {
            var newMax = maxElement(data)
            if newMax > max {
                max = newMax
            }
        }
        return max
    }
    
    
    
    /**
     * Get maximum value in all arrays in data store.
     */
    private func getMinimumValue() -> CGFloat {
        var min: CGFloat = 0
        for data in dataStore {
            var newMin = minElement(data)
            if newMin < min {
                min = newMin
            }
        }
        return min
    }
    
    
    
    /**
     * Draw line.
     */
    private func drawLine(lineIndex: Int) {
        
        var data = self.dataStore[lineIndex]
        var path = UIBezierPath()
        
        var x = self.xScale(0) + axes.inset
        var y = self.bounds.height - self.yScale(data[0]) - axes.inset
        path.moveToPoint(CGPoint(x: x, y: y))
        for index in 1..<data.count {
            x = self.xScale(CGFloat(index)) + axes.inset
            y = self.bounds.height - self.yScale(data[index]) - axes.inset
            path.addLineToPoint(CGPoint(x: x, y: y))
        }
        
        var layer = CAShapeLayer()
        layer.frame = self.bounds
        layer.path = path.CGPath
        layer.strokeColor = colors[lineIndex].CGColor
        layer.fillColor = nil
        layer.lineWidth = lineWidth
        self.layer.addSublayer(layer)
        
        // animate line drawing
        if animation.enabled {
            var anim = CABasicAnimation(keyPath: "strokeEnd")
            anim.duration = animation.duration
            anim.fromValue = 0
            anim.toValue = 1
            layer.addAnimation(anim, forKey: "strokeEnd")
        }
        
        // add line layer to store
        lineLayerStore.append(layer)
    }
    
    
    
    /**
     * Fill area between line chart and x-axis.
     */
    private func drawAreaBeneathLineChart(lineIndex: Int) {
        
        var data = self.dataStore[lineIndex]
        var path = UIBezierPath()
        
        colors[lineIndex].colorWithAlphaComponent(0.2).setFill()
        // move to origin
        path.moveToPoint(CGPoint(x: axes.inset, y: self.bounds.height - self.yScale(0) - axes.inset))
        // add line to first data point
        path.addLineToPoint(CGPoint(x: axes.inset, y: self.bounds.height - self.yScale(data[0]) - axes.inset))
        // draw whole line chart
        for index in 1..<data.count {
            var x = self.xScale(CGFloat(index)) + axes.inset
            var y = self.bounds.height - self.yScale(data[index]) - axes.inset
            path.addLineToPoint(CGPoint(x: x, y: y))
        }
        // move down to x axis
        path.addLineToPoint(CGPoint(x: self.xScale(CGFloat(data.count - 1)) + axes.inset, y: self.bounds.height - self.yScale(0) - axes.inset))
        // move to origin
        path.addLineToPoint(CGPoint(x: axes.inset, y: self.bounds.height - self.yScale(0) - axes.inset))
        path.fill()
    }
    
    
    
    /**
     * Draw x grid.
     */
    private func drawXGrid() {
        grid.color.setStroke()
        var path = UIBezierPath()
        var x: CGFloat
        var y1: CGFloat = self.bounds.height - axes.inset
        var y2: CGFloat = axes.inset
        var (start, stop, step) = self.xTicks
        for var i: CGFloat = start; i <= stop; i += step {
            x = self.xScale(i) + axes.inset
            path.moveToPoint(CGPoint(x: x, y: y1))
            path.addLineToPoint(CGPoint(x: x, y: y2))
        }
        path.stroke()
    }
    
    
    
    /**
     * Draw y grid.
     */
    private func drawYGrid() {
        grid.color.setStroke()
        var path = UIBezierPath()
        var x1: CGFloat = axes.inset
        var x2: CGFloat = self.bounds.width - axes.inset
        var y: CGFloat
        var (start, stop, step) = self.yTicks
        for var i: CGFloat = start; i <= stop; i += step {
            y = self.bounds.height - self.yScale(i) - axes.inset
            path.moveToPoint(CGPoint(x: x1, y: y))
            path.addLineToPoint(CGPoint(x: x2, y: y))
        }
        path.stroke()
    }
    
    
    
    /**
     * Draw grid.
     */
    private func drawGrid() {
        drawXGrid()
        drawYGrid()
    }
    
    
    
    /**
     * Draw x labels.
     */
    private func drawXLabels() {
        var xAxisData = self.dataStore[0]
        var y = self.bounds.height - axes.inset
        for (index, value) in enumerate(xAxisData) {
            var x = self.xScale(CGFloat(index)) + (axes.inset / 2)
            var label = UILabel(frame: CGRect(x: x, y: y, width: axes.inset, height: axes.inset))
            label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
            label.textAlignment = .Center
            label.text = String(index)
            self.addSubview(label)
        }
    }
    
    
    
    /**
     * Draw y labels.
     */
    private func drawYLabels() {
        var yValue: CGFloat
        var (start, stop, step) = self.yTicks
        for var i: CGFloat = start; i <= stop; i += step {
            yValue = self.bounds.height - self.yScale(i) - (axes.inset * 1.5)
            var label = UILabel(frame: CGRect(x: 0, y: yValue, width: axes.inset, height: axes.inset))
            label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
            label.textAlignment = .Center
            label.text = String(Int(round(i)))
            self.addSubview(label)
        }
    }
    
    
    
    /**
     * Add line chart
     */
    public func addLine(data: [CGFloat]) {
        self.dataStore.append(data)
        self.setNeedsDisplay()
    }
    
    
    
    /**
     * Make whole thing white again.
     */
    public func clearAll() {
        self.removeAll = true
        clear()
        self.setNeedsDisplay()
        self.removeAll = false
    }
    
    
    
    /**
     * Remove charts, areas and labels but keep axis and grid.
     */
    public func clear() {
        // clear data
        dataStore.removeAll()
        self.setNeedsDisplay()
    }
}