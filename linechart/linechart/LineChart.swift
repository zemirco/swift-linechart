


import UIKit
import QuartzCore



// make Arrays substractable
func - (left: [CGFloat], right: [CGFloat]) -> [CGFloat] {
    var result: [CGFloat] = []
    for index in 0..<left.count {
        var difference = left[index] - right[index]
        result.append(difference)
    }
    return result
}



// delegate method
protocol LineChartDelegate {
    func didSelectDataPoint(x: CGFloat, yValues: [CGFloat])
}



// LineChart class
class LineChart: UIView {
    
    // default configuration
    var gridVisible = true
    var axesVisible = true
    var dotsVisible = true
    var labelsXVisible = false
    var labelsYVisible = false
    var areaUnderLinesVisible = false
    var numberOfGridLinesX: CGFloat = 10
    var numberOfGridLinesY: CGFloat = 10
    var animationEnabled = true
    var animationDuration: CFTimeInterval = 1
    
    var dotsBackgroundColor = UIColor.whiteColor()
    
    // #eeeeee
    var gridColor = UIColor(red: 238/255.0, green: 238/255.0, blue: 238/255.0, alpha: 1)
    
    // #607d8b
    var axesColor = UIColor(red: 96/255.0, green: 125/255.0, blue: 139/255.0, alpha: 1)
    
    // #f69988
    var positiveAreaColor = UIColor(red: 246/255.0, green: 153/255.0, blue: 136/255.0, alpha: 1)
    
    // #72d572
    var negativeAreaColor = UIColor(red: 114/255.0, green: 213/255.0, blue: 114/255.0, alpha: 1)
    
    var areaBetweenLines = [-1, -1]
    
    // sizes
    var lineWidth: CGFloat = 2
    var outerRadius: CGFloat = 12
    var innerRadius: CGFloat = 8
    var outerRadiusHighlighted: CGFloat = 12
    var innerRadiusHighlighted: CGFloat = 8
    var axisInset: CGFloat = 15
    
    private var xScale: ((CGFloat) -> CGFloat)!
    private var xInvert: ((CGFloat) -> CGFloat)!
    private var xTicks: (CGFloat, CGFloat, CGFloat)!
    
    private var yScale: ((CGFloat) -> CGFloat)!
    private var yTicks: (CGFloat, CGFloat, CGFloat)!

    
    // values calculated on init
    var drawingHeight: CGFloat = 0 {
        didSet {
            var data = dataStore[0]
            var scale = LinearScale(domain: [minElement(data), maxElement(data)], range: [0, drawingHeight])
            yScale = scale.scale()
            yTicks = scale.ticks(10)
        }
    }
    var drawingWidth: CGFloat = 0 {
        didSet {
            var data = dataStore[0]
            var scale = LinearScale(domain: [0.0, CGFloat(count(data) - 1)], range: [0, drawingWidth])
            xScale = scale.scale()
            xInvert = scale.invert()
            xTicks = scale.ticks(10)
        }
    }
    
    var delegate: LineChartDelegate?
    
    // data stores
    var dataStore: [[CGFloat]] = []
    
    
    
    var dotsDataStore: [[DotCALayer]] = []
    var lineLayerStore: [CAShapeLayer] = []
    var colors: [UIColor] = []
    
    var removeAll: Bool = false
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clearColor()
        
        // category10 colors from d3 - https://github.com/mbostock/d3/wiki/Ordinal-Scales
        self.colors = [
            UIColorFromHex(0x1f77b4),
            UIColorFromHex(0xff7f0e),
            UIColorFromHex(0x2ca02c),
            UIColorFromHex(0xd62728),
            UIColorFromHex(0x9467bd),
            UIColorFromHex(0x8c564b),
            UIColorFromHex(0xe377c2),
            UIColorFromHex(0x7f7f7f),
            UIColorFromHex(0xbcbd22),
            UIColorFromHex(0x17becf)
        ]
    }
    
    
    
    convenience override init() {
        self.init(frame: CGRectZero)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func drawRect(rect: CGRect) {
        
        if removeAll {
            var context = UIGraphicsGetCurrentContext()
            CGContextClearRect(context, rect)
            return
        }
        
        self.drawingHeight = self.bounds.height - (2 * axisInset)
        self.drawingWidth = self.bounds.width - (2 * axisInset)
        
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
        if gridVisible { drawGrid() }
        
        // draw axes
        if axesVisible { drawAxes() }
        
        // draw labels
        if labelsXVisible { drawXLabels() }
        if labelsYVisible { drawYLabels() }
        
        // draw filled area between charts
//        if areaBetweenLines[0] > -1 && areaBetweenLines[1] > -1 {
//            drawAreaBetweenLineCharts()
//        }
        
        // draw lines
        for (lineIndex, lineData) in enumerate(dataStore) {
            
            drawLine(lineIndex)
            
            // draw dots
            if dotsVisible { drawDataDots(lineIndex) }
            
            // draw area under line chart
            if areaUnderLinesVisible { drawAreaBeneathLineChart(lineIndex) }
            
        }
        
    }
    
    
    
    /**
     * Convert hex color to UIColor
     */
    func UIColorFromHex(hex: Int) -> UIColor {
        var red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        var green = CGFloat((hex & 0xFF00) >> 8) / 255.0
        var blue = CGFloat((hex & 0xFF)) / 255.0
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
    
    
    
    /**
     * Lighten color.
     */
    func lightenUIColor(color: UIColor) -> UIColor {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: b * 1.5, alpha: a)
    }
    
    
    
    /**
     * Get y value for given x value. Or return zero or maximum value.
     */
    func getYValuesForXValue(x: Int) -> [CGFloat] {
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
    func handleTouchEvents(touches: NSSet!, event: UIEvent) {
        if (self.dataStore.isEmpty) {
            return
        }
        var point: AnyObject! = touches.anyObject()
        var xValue = point.locationInView(self).x
        var inverted = self.xInvert(xValue - axisInset)
        var rounded = Int(round(Double(inverted)))
        var yValues: [CGFloat] = getYValuesForXValue(rounded)
        highlightDataPoints(rounded)
        delegate?.didSelectDataPoint(CGFloat(rounded), yValues: yValues)
    }
    
    
    
    /**
     * Listen on touch end event.
     */
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        handleTouchEvents(touches, event: event)
    }
    
    
    
    /**
     * Listen on touch move event
     */
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        handleTouchEvents(touches, event: event)
    }
    
    
    
    /**
     * Highlight data points at index.
     */
    func highlightDataPoints(index: Int) {
        for (lineIndex, dotsData) in enumerate(dotsDataStore) {
            // make all dots white again
            for dot in dotsData {
                dot.backgroundColor = dotsBackgroundColor.CGColor
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
            dot.backgroundColor = lightenUIColor(colors[lineIndex]).CGColor
        }
    }
    
    
    
    /**
     * Draw small dot at every data point.
     */
    func drawDataDots(lineIndex: Int) {
        var dots: [DotCALayer] = []
        var data = self.dataStore[lineIndex]
        
        for index in 0..<data.count {
            var xValue = self.xScale(CGFloat(index)) + axisInset - outerRadius/2
            var yValue = self.bounds.height - self.yScale(data[index]) - axisInset - outerRadius/2
            
            // draw custom layer with another layer in the center
            var dotLayer = DotCALayer()
            dotLayer.dotInnerColor = colors[lineIndex]
            dotLayer.innerRadius = innerRadius
            dotLayer.backgroundColor = dotsBackgroundColor.CGColor
            dotLayer.cornerRadius = outerRadius / 2
            dotLayer.frame = CGRect(x: xValue, y: yValue, width: outerRadius, height: outerRadius)
            self.layer.addSublayer(dotLayer)
            dots.append(dotLayer)
            
            // animate opacity
            if animationEnabled {
                var animation = CABasicAnimation(keyPath: "opacity")
                animation.duration = animationDuration
                animation.fromValue = 0
                animation.toValue = 1
                dotLayer.addAnimation(animation, forKey: "opacity")
            }
            
        }
        dotsDataStore.append(dots)
    }
    
    
    
    /**
     * Draw x and y axis.
     */
    func drawAxes() {
        var height = self.bounds.height
        var width = self.bounds.width
        var path = UIBezierPath()
        axesColor.setStroke()
        // draw x-axis
        var y0 = height - self.yScale(0) - axisInset
        path.moveToPoint(CGPoint(x: axisInset, y: y0))
        path.addLineToPoint(CGPoint(x: width - axisInset, y: y0))
        path.stroke()
        // draw y-axis
        path.moveToPoint(CGPoint(x: axisInset, y: height - axisInset))
        path.addLineToPoint(CGPoint(x: axisInset, y: axisInset))
        path.stroke()
    }
    
    
    
    /**
     * Get maximum value in all arrays in data store.
     */
//    func getMaximumValue() -> CGFloat {
//        var max: CGFloat = 1
//        for data in dataStore {
//            var newMax = maxElement(data)
//            if newMax > max {
//                max = newMax
//            }
//        }
//        return max
//    }
    
    
    
    /**
     * Scale data to fit drawing height.
     */
//    func scaleDataYAxis(data: [CGFloat]) -> [CGFloat] {
//        var maximumYValue = getMaximumValue()
//        var factor = drawingHeight / maximumYValue
//        var scaledDataYAxis = data.map({datum -> CGFloat in
//            var newYValue = datum * factor
//            return newYValue
//            })
//        return scaledDataYAxis
//    }
    
    
    
    /**
     * Draw line.
     */
    func drawLine(lineIndex: Int) {
        
        var data = self.dataStore[lineIndex]
        var path = UIBezierPath()
        
        var x = self.xScale(0) + axisInset
        var y = self.bounds.height - self.yScale(data[0]) - axisInset
        path.moveToPoint(CGPoint(x: x, y: y))
        for index in 1..<data.count {
            x = self.xScale(CGFloat(index)) + axisInset
            y = self.bounds.height - self.yScale(data[index]) - axisInset
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
        if animationEnabled {
            var animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.duration = animationDuration
            animation.fromValue = 0
            animation.toValue = 1
            layer.addAnimation(animation, forKey: "strokeEnd")
        }
        
        // add line layer to store
        lineLayerStore.append(layer)
    }
    
    
    /**
     * Fill area between line chart and x-axis.
     */
    func drawAreaBeneathLineChart(lineIndex: Int) {
        
        var data = self.dataStore[lineIndex]
        var path = UIBezierPath()
        
        colors[lineIndex].colorWithAlphaComponent(0.2).setFill()
        // move to origin
        path.moveToPoint(CGPoint(x: axisInset, y: self.bounds.height - self.yScale(0) - axisInset))
        // add line to first data point
        path.addLineToPoint(CGPoint(x: axisInset, y: self.bounds.height - self.yScale(data[0]) - axisInset))
        // draw whole line chart
        for index in 1..<data.count {
            var x = self.xScale(CGFloat(index)) + axisInset
            var y = self.bounds.height - self.yScale(data[index]) - axisInset
            path.addLineToPoint(CGPoint(x: x, y: y))
        }
        // move down to x axis
        path.addLineToPoint(CGPoint(x: self.xScale(CGFloat(data.count - 1)) + axisInset, y: self.bounds.height - self.yScale(0) - axisInset))
        // move to origin
        path.addLineToPoint(CGPoint(x: axisInset, y: self.bounds.height - self.yScale(0) - axisInset))
        path.fill()
    }
    
    
    
    /**
     * Fill area between charts.
     */
//    func drawAreaBetweenLineCharts() {
//        
//        var xAxis = scaleDataXAxis(dataStore[0])
//        var yAxisDataA = scaleDataYAxis(dataStore[areaBetweenLines[0]])
//        var yAxisDataB = scaleDataYAxis(dataStore[areaBetweenLines[1]])
//        var difference = yAxisDataA - yAxisDataB
//        
//        for index in 0..<xAxis.count-1 {
//            
//            var context = UIGraphicsGetCurrentContext()
//            
//            if difference[index] < 0 {
//                CGContextSetFillColorWithColor(context, negativeAreaColor.CGColor)
//            } else {
//                CGContextSetFillColorWithColor(context, positiveAreaColor.CGColor)
//            }
//            
//            var point1XValue = xAxis[index] + axisInset
//            var point1YValue = self.bounds.height - yAxisDataA[index] - axisInset
//            var point2XValue = xAxis[index] + axisInset
//            var point2YValue = self.bounds.height - yAxisDataB[index] - axisInset
//            var point3XValue = xAxis[index+1] + axisInset
//            var point3YValue = self.bounds.height - yAxisDataB[index+1] - axisInset
//            var point4XValue = xAxis[index+1] + axisInset
//            var point4YValue = self.bounds.height - yAxisDataA[index+1] - axisInset
//            
//            CGContextMoveToPoint(context, point1XValue, point1YValue)
//            CGContextAddLineToPoint(context, point2XValue, point2YValue)
//            CGContextAddLineToPoint(context, point3XValue, point3YValue)
//            CGContextAddLineToPoint(context, point4XValue, point4YValue)
//            CGContextAddLineToPoint(context, point1XValue, point1YValue)
//            CGContextFillPath(context)
//            
//        }
//        
//    }
    
    
    
    /**
     * Draw x grid.
     */
    func drawXGrid() {
        gridColor.setStroke()
        var path = UIBezierPath()
        var x: CGFloat
        var y1: CGFloat = self.bounds.height - axisInset
        var y2: CGFloat = axisInset
        var (start, stop, step) = self.xTicks
        for var i: CGFloat = start; i <= stop; i += step {
            x = self.xScale(i) + axisInset
            path.moveToPoint(CGPoint(x: x, y: y1))
            path.addLineToPoint(CGPoint(x: x, y: y2))
        }
        path.stroke()
    }
    
    
    
    /**
     * Draw y grid.
     */
    func drawYGrid() {
        gridColor.setStroke()
        var path = UIBezierPath()
        var x1: CGFloat = axisInset
        var x2: CGFloat = self.bounds.width - axisInset
        var y: CGFloat
        var (start, stop, step) = self.yTicks
        for var i: CGFloat = start; i <= stop; i += step {
            y = self.bounds.height - self.yScale(i) - axisInset
            path.moveToPoint(CGPoint(x: x1, y: y))
            path.addLineToPoint(CGPoint(x: x2, y: y))
        }
        path.stroke()
    }
    
    
    
    /**
     * Draw grid.
     */
    func drawGrid() {
        drawXGrid()
        drawYGrid()
    }
    
    
    
    /**
     * Draw x labels.
     */
    func drawXLabels() {
        var xAxisData = self.dataStore[0]
        var y = self.bounds.height - axisInset
        for (index, value) in enumerate(xAxisData) {
            var x = self.xScale(CGFloat(index)) + (axisInset / 2)
            var label = UILabel(frame: CGRect(x: x, y: y, width: axisInset, height: axisInset))
            label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
            label.textAlignment = .Center
            label.text = String(index)
            self.addSubview(label)
        }
    }
    
    
    
    /**
     * Draw y labels.
     */
    func drawYLabels() {
        var yValue: CGFloat
        var (start, stop, step) = self.yTicks
        for var i: CGFloat = start; i <= stop; i += step {
            yValue = self.bounds.height - self.yScale(i) - (axisInset * 1.5)
            var label = UILabel(frame: CGRect(x: 0, y: yValue, width: axisInset, height: axisInset))
            label.font = UIFont.preferredFontForTextStyle(UIFontTextStyleCaption2)
            label.textAlignment = .Center
            label.text = String(Int(round(i)))
            self.addSubview(label)
        }
    }
    
    
    
    /**
     * Add line chart
     */
    func addLine(data: [CGFloat]) {
        self.dataStore.append(data)
        self.setNeedsDisplay()
    }
    
    
    /**
     * Make whole thing white again.
     */
    func clearAll() {
        self.removeAll = true
        clear()
        self.setNeedsDisplay()
        self.removeAll = false
    }
    
    
    
    /**
     * Remove charts, areas and labels but keep axis and grid.
     */
    func clear() {
        // clear data
        dataStore.removeAll()
        self.setNeedsDisplay()
    }
}