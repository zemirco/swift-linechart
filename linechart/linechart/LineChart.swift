


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

public struct Labels {
    public var visible: Bool = true
    public var values: [String] = []
}

public struct Grid {
    public var visible: Bool = true
    public var count: CGFloat = 10
    // #eeeeee
    public var color: UIColor = UIColor(red: 238/255.0, green: 238/255.0, blue: 238/255.0, alpha: 1)
}

public struct Axis {
    public var visible: Bool = true
    // #607d8b
    public var color: UIColor = UIColor(red: 96/255.0, green: 125/255.0, blue: 139/255.0, alpha: 1)
    public var inset: CGFloat = 15
}

public struct Coordinate {
    // public
    public var labels: Labels = Labels()
    public var grid: Grid = Grid()
    public var axis: Axis = Axis()
    
    // private
    private var linear: LinearScale!
    private var scale: ((CGFloat) -> CGFloat)!
    private var invert: ((CGFloat) -> CGFloat)!
    private var ticks: (CGFloat, CGFloat, CGFloat)!
}

public struct Animation {
    public var enabled: Bool = true
    public var duration: CFTimeInterval = 1
}

public struct Dots {
    public var visible: Bool = true
    public var color: UIColor = UIColor.whiteColor()
    public var innerRadius: CGFloat = 8
    public var outerRadius: CGFloat = 12
    public var innerRadiusHighlighted: CGFloat = 8
    public var outerRadiusHighlighted: CGFloat = 12
}



/**
 * LineChart
 */
public class LineChart: UIView {
    
    // default configuration
    public var area: Bool = true
    public var animation: Animation = Animation()
    public var dots: Dots = Dots()
    public var lineWidth: CGFloat = 2
    
    public var x: Coordinate = Coordinate()
    public var y: Coordinate = Coordinate()

    
    // values calculated on init
    private var drawingHeight: CGFloat = 0 {
        didSet {
            var max = getMaximumValue()
            var min = getMinimumValue()
            y.linear = LinearScale(domain: [min, max], range: [0, drawingHeight])
            y.scale = y.linear.scale()
            y.ticks = y.linear.ticks(Int(y.grid.count))
        }
    }
    private var drawingWidth: CGFloat = 0 {
        didSet {
            var data = dataStore[0]
            x.linear = LinearScale(domain: [0.0, CGFloat(count(data) - 1)], range: [0, drawingWidth])
            x.scale = x.linear.scale()
            x.invert = x.linear.invert()
            x.ticks = x.linear.ticks(Int(x.grid.count))
        }
    }
    
    public var delegate: LineChartDelegate?
    
    // data stores
    private var dataStore: [[CGFloat]] = []
    private var dotsDataStore: [[DotCALayer]] = []
    private var lineLayerStore: [CAShapeLayer] = []
    
    private var removeAll: Bool = false
    
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

    convenience init() {
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
        
        self.drawingHeight = self.bounds.height - (2 * y.axis.inset)
        self.drawingWidth = self.bounds.width - (2 * x.axis.inset)
        
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
        if x.grid.visible && y.grid.visible { drawGrid() }
        
        // draw axes
        if x.axis.visible && y.axis.visible { drawAxes() }
        
        // draw labels
        if x.labels.visible { drawXLabels() }
        if y.labels.visible { drawYLabels() }
        
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
        var inverted = self.x.invert(xValue - x.axis.inset)
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
            var xValue = self.x.scale(CGFloat(index)) + x.axis.inset - dots.outerRadius/2
            var yValue = self.bounds.height - self.y.scale(data[index]) - y.axis.inset - dots.outerRadius/2
            
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
        // draw x-axis
        x.axis.color.setStroke()
        var y0 = height - self.y.scale(0) - y.axis.inset
        path.moveToPoint(CGPoint(x: x.axis.inset, y: y0))
        path.addLineToPoint(CGPoint(x: width - x.axis.inset, y: y0))
        path.stroke()
        // draw y-axis
        y.axis.color.setStroke()
        path.moveToPoint(CGPoint(x: x.axis.inset, y: height - y.axis.inset))
        path.addLineToPoint(CGPoint(x: x.axis.inset, y: y.axis.inset))
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
        
        var xValue = self.x.scale(0) + x.axis.inset
        var yValue = self.bounds.height - self.y.scale(data[0]) - y.axis.inset
        path.moveToPoint(CGPoint(x: xValue, y: yValue))
        for index in 1..<data.count {
            xValue = self.x.scale(CGFloat(index)) + x.axis.inset
            yValue = self.bounds.height - self.y.scale(data[index]) - y.axis.inset
            path.addLineToPoint(CGPoint(x: xValue, y: yValue))
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
        path.moveToPoint(CGPoint(x: x.axis.inset, y: self.bounds.height - self.y.scale(0) - y.axis.inset))
        // add line to first data point
        path.addLineToPoint(CGPoint(x: x.axis.inset, y: self.bounds.height - self.y.scale(data[0]) - y.axis.inset))
        // draw whole line chart
        for index in 1..<data.count {
            var x1 = self.x.scale(CGFloat(index)) + x.axis.inset
            var y1 = self.bounds.height - self.y.scale(data[index]) - y.axis.inset
            path.addLineToPoint(CGPoint(x: x1, y: y1))
        }
        // move down to x axis
        path.addLineToPoint(CGPoint(x: self.x.scale(CGFloat(data.count - 1)) + x.axis.inset, y: self.bounds.height - self.y.scale(0) - y.axis.inset))
        // move to origin
        path.addLineToPoint(CGPoint(x: x.axis.inset, y: self.bounds.height - self.y.scale(0) - y.axis.inset))
        path.fill()
    }
    
    
    
    /**
     * Draw x grid.
     */
    private func drawXGrid() {
        x.grid.color.setStroke()
        var path = UIBezierPath()
        var x1: CGFloat
        var y1: CGFloat = self.bounds.height - y.axis.inset
        var y2: CGFloat = y.axis.inset
        var (start, stop, step) = self.x.ticks
        for var i: CGFloat = start; i <= stop; i += step {
            x1 = self.x.scale(i) + x.axis.inset
            path.moveToPoint(CGPoint(x: x1, y: y1))
            path.addLineToPoint(CGPoint(x: x1, y: y2))
        }
        path.stroke()
    }
    
    
    
    /**
     * Draw y grid.
     */
    private func drawYGrid() {
        self.y.grid.color.setStroke()
        var path = UIBezierPath()
        var x1: CGFloat = x.axis.inset
        var x2: CGFloat = self.bounds.width - x.axis.inset
        var y1: CGFloat
        var (start, stop, step) = self.y.ticks
        for var i: CGFloat = start; i <= stop; i += step {
            y1 = self.bounds.height - self.y.scale(i) - y.axis.inset
            path.moveToPoint(CGPoint(x: x1, y: y1))
            path.addLineToPoint(CGPoint(x: x2, y: y1))
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
        var y = self.bounds.height - x.axis.inset
        var (start, stop, step) = x.linear.ticks(xAxisData.count)
        var width = x.scale(step)
        
        var text: String
        for (index, value) in enumerate(xAxisData) {
            var xValue = self.x.scale(CGFloat(index)) + x.axis.inset - (width / 2)
            var label = UILabel(frame: CGRect(x: xValue, y: y, width: width, height: x.axis.inset))
            label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
            label.textAlignment = .Center
            if (x.labels.values.count != 0) {
                text = x.labels.values[index]
            } else {
                text = String(index)
            }
            label.text = text
            self.addSubview(label)
        }
    }
    
    
    
    /**
     * Draw y labels.
     */
    private func drawYLabels() {
        var yValue: CGFloat
        var (start, stop, step) = self.y.ticks
        for var i: CGFloat = start; i <= stop; i += step {
            yValue = self.bounds.height - self.y.scale(i) - (y.axis.inset * 1.5)
            var label = UILabel(frame: CGRect(x: 0, y: yValue, width: y.axis.inset, height: y.axis.inset))
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



/**
 * DotCALayer
 */
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



/**
 * LinearScale
 */
public class LinearScale {
    
    var domain: [CGFloat]
    var range: [CGFloat]
    
    public init(domain: [CGFloat] = [0, 1], range: [CGFloat] = [0, 1]) {
        self.domain = domain
        self.range = range
    }
    
    public func scale() -> (x: CGFloat) -> CGFloat {
        return bilinear(domain, range: range, uninterpolate: uninterpolate, interpolate: interpolate)
    }
    
    public func invert() -> (x: CGFloat) -> CGFloat {
        return bilinear(range, range: domain, uninterpolate: uninterpolate, interpolate: interpolate)
    }
    
    public func ticks(m: Int) -> (CGFloat, CGFloat, CGFloat) {
        return scale_linearTicks(domain, m: m)
    }
    
    private func scale_linearTicks(domain: [CGFloat], m: Int) -> (CGFloat, CGFloat, CGFloat) {
        return scale_linearTickRange(domain, m: m)
    }
    
    private func scale_linearTickRange(domain: [CGFloat], m: Int) -> (CGFloat, CGFloat, CGFloat) {
        var extent = scaleExtent(domain)
        var span = extent[1] - extent[0]
        var step = CGFloat(pow(10, floor(log(Double(span) / Double(m)) / M_LN10)))
        var err = CGFloat(m) / span * step
        
        // Filter ticks to get closer to the desired count.
        if (err <= 0.15) {
            step *= 10
        } else if (err <= 0.35) {
            step *= 5
        } else if (err <= 0.75) {
            step *= 2
        }
        
        // Round start and stop values to step interval.
        var start = ceil(extent[0] / step) * step
        var stop = floor(extent[1] / step) * step + step * 0.5 // inclusive
        
        return (start, stop, step)
    }
    
    private func scaleExtent(domain: [CGFloat]) -> [CGFloat] {
        var start = domain[0]
        var stop = domain[count(domain) - 1]
        return start < stop ? [start, stop] : [stop, start]
    }
    
    private func interpolate(a: CGFloat, b: CGFloat) -> (c: CGFloat) -> CGFloat {
        var diff = b - a
        func f(c: CGFloat) -> CGFloat {
            return (a + diff) * c
        }
        return f
    }
    
    private func uninterpolate(a: CGFloat, b: CGFloat) -> (c: CGFloat) -> CGFloat {
        var diff = b - a
        var re = diff != 0 ? 1 / diff : 0
        func f(c: CGFloat) -> CGFloat {
            return (c - a) * re
        }
        return f
    }
    
    private func bilinear(domain: [CGFloat], range: [CGFloat], uninterpolate: (a: CGFloat, b: CGFloat) -> (c: CGFloat) -> CGFloat, interpolate: (a: CGFloat, b: CGFloat) -> (c: CGFloat) -> CGFloat) -> (c: CGFloat) -> CGFloat {
        var u: (c: CGFloat) -> CGFloat = uninterpolate(a: domain[0], b: domain[1])
        var i: (c: CGFloat) -> CGFloat = interpolate(a: range[0], b: range[1])
        func f(d: CGFloat) -> CGFloat {
            return i(c: u(c: d))
        }
        return f
    }
    
}