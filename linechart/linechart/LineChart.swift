


import UIKit
import QuartzCore



// make Arrays substractable
@infix func - (left: Array<CGFloat>, right: Array<CGFloat>) -> Array<CGFloat> {
    var result: Array<CGFloat> = []
    for index in 0..left.count {
        var difference = left[index] - right[index]
        result.append(difference)
    }
    return result
}



// delegate method
@objc protocol LineChartDelegate {
    func didSelectDataPoint(x: CGFloat, yValues: Array<CGFloat>)
}



// LineChart class
class LineChart: UIControl {
    
    // default configuration
    var gridVisible = true
    var axesVisible = true
    var dotsVisible = true
    var numberOfGridLinesX: CGFloat = 10
    var numberOfGridLinesY: CGFloat = 10
    
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
    var dotsSize: CGFloat = 12
    var dotsBorderWidth: CGFloat = 4
    var axisInset: CGFloat = 10
    
    // values calculated on init
    var drawingHeight: CGFloat = 0
    var drawingWidth: CGFloat = 0
    
    var delegate: LineChartDelegate?
    
    // data stores
    var dataStore: Array<Array<CGFloat>> = []
    var dotsDataStore: Array<Array<DotCALayer>> = []
    var colors: Array<UIColor> = []
    
    
    
    init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
    }
    
    
    
    convenience init() {
        self.init(frame: CGRectZero)
    }
    
    
    
    override func drawRect(rect: CGRect) {
        
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
        
        self.drawingHeight = self.bounds.height - (2 * axisInset)
        self.drawingWidth = self.bounds.width - (2 * axisInset)
        
        // remove all dots on device rotation
        if dotsDataStore.count > 0 {
            for dotsData in dotsDataStore {
                for dot in dotsData {
                    dot.removeFromSuperlayer()
                }
            }
            dotsDataStore.removeAll()
        }
        
        // draw grid
        if gridVisible { drawGrid() }
        
        // draw axes
        if axesVisible { drawAxes() }
        
        // draw filled area between charts
        if areaBetweenLines[0] > -1 && areaBetweenLines[1] > -1 {
            drawAreaBetweenLineCharts()
        }
        
        // draw lines
        for (lineIndex, lineData) in enumerate(dataStore) {
            var scaledDataXAxis = scaleDataXAxis(lineData)
            var scaledDataYAxis = scaleDataYAxis(lineData)
            drawLine(scaledDataXAxis, yAxis: scaledDataYAxis, lineIndex: lineIndex)
            
            // draw dots
            if dotsVisible { drawDataDots(scaledDataXAxis, yAxis: scaledDataYAxis, lineIndex: lineIndex) }
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
    func getYValuesForXValue(x: Int) -> Array<CGFloat> {
        var result: Array<CGFloat> = []
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
    func handleTouchEvents(touches: NSSet!, event: UIEvent!) {
        var point: AnyObject! = touches.anyObject()
        var xValue = point.locationInView(self).x
        var closestXValueIndex = findClosestXValueInData(xValue)
        var yValues: Array<CGFloat> = getYValuesForXValue(closestXValueIndex)
        highlightDataPoints(closestXValueIndex)
        delegate?.didSelectDataPoint(CGFloat(closestXValueIndex), yValues: yValues)
    }
    
    
    
    /**
     * Listen on touch end event.
     */
    override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {
        handleTouchEvents(touches, event: event)
    }
    
    
    
    /**
     * Listen on touch move event
     */
    override func touchesMoved(touches: NSSet!, withEvent event: UIEvent!) {
        handleTouchEvents(touches, event: event)
    }
    
    
    
    /**
     * Find closest value on x axis.
     */
    func findClosestXValueInData(xValue: CGFloat) -> Int {
        var scaledDataXAxis = scaleDataXAxis(dataStore[0])
        var difference = scaledDataXAxis[1] - scaledDataXAxis[0]
        var dividend = (xValue - axisInset) / difference
        var roundedDividend = Int(round(Double(dividend)))
        return roundedDividend
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
    func drawDataDots(xAxis: Array<CGFloat>, yAxis: Array<CGFloat>, lineIndex: Int) {
        var dots: Array<DotCALayer> = []
        for index in 0..xAxis.count {
            var xValue = xAxis[index] + axisInset - dotsSize/2
            var yValue = self.bounds.height - yAxis[index] - axisInset - dotsSize/2
            
            // draw custom layer with another layer in the center
            var dotLayer = DotCALayer()
            dotLayer.dotInnerColor = colors[lineIndex]
            dotLayer.dotBorderWith = dotsBorderWidth
            dotLayer.backgroundColor = dotsBackgroundColor.CGColor
            dotLayer.cornerRadius = dotsSize / 2
            dotLayer.frame = CGRect(x: xValue, y: yValue, width: dotsSize, height: dotsSize)
            self.layer.addSublayer(dotLayer)
            dots.append(dotLayer)
        }
        dotsDataStore.append(dots)
    }
    
    
    
    /**
     * Draw x and y axis.
     */
    func drawAxes() {
        var height = self.bounds.height
        var width = self.bounds.width
        var context = UIGraphicsGetCurrentContext()
        CGContextSetStrokeColorWithColor(context, axesColor.CGColor)
        // draw x-axis
        CGContextMoveToPoint(context, axisInset, height-axisInset)
        CGContextAddLineToPoint(context, width-axisInset, height-axisInset)
        CGContextStrokePath(context)
        // draw y-axis
        CGContextMoveToPoint(context, axisInset, height-axisInset)
        CGContextAddLineToPoint(context, axisInset, axisInset)
        CGContextStrokePath(context)
    }
    
    
    
    /**
     * Get maximum value in all arrays in data store.
     */
    func getMaximumValue() -> CGFloat {
        var maximum = 0
        for data in dataStore {
            var newMaximum = data.reduce(Int.min, { max(Int($0), Int($1)) })
            if newMaximum > maximum {
                maximum = newMaximum
            }
        }
        return CGFloat(maximum)
    }
    
    
    
    /**
     * Scale to fit drawing width.
     */
    func scaleDataXAxis(data: Array<CGFloat>) -> Array<CGFloat> {
        var factor = drawingWidth / CGFloat(data.count - 1)
        var scaledDataXAxis: Array<CGFloat> = []
        for index in 0..data.count {
            var newXValue = factor * CGFloat(index)
            scaledDataXAxis.append(newXValue)
        }
        return scaledDataXAxis
    }
    
    
    
    /**
     * Scale data to fit drawing height.
     */
    func scaleDataYAxis(data: Array<CGFloat>) -> Array<CGFloat> {
        var maximumYValue = getMaximumValue()
        var factor = drawingHeight / maximumYValue
        var scaledDataYAxis = data.map({datum -> CGFloat in
            var newYValue = datum * factor
            return newYValue
            })
        return scaledDataYAxis
    }
    
    
    
    /**
     * Draw line.
     */
    func drawLine(xAxis: Array<CGFloat>, yAxis: Array<CGFloat>, lineIndex: Int) {
        var context = UIGraphicsGetCurrentContext()
        CGContextSetLineWidth(context, lineWidth)
        CGContextSetStrokeColorWithColor(context, colors[lineIndex].CGColor)
        CGContextMoveToPoint(context, axisInset, self.bounds.height - yAxis[0] - axisInset)
        for index in 1..xAxis.count {
            var xValue = xAxis[index] + axisInset
            var yValue = self.bounds.height - yAxis[index] - axisInset
            CGContextAddLineToPoint(context, xValue, yValue)
        }
        CGContextStrokePath(context)
    }
    
    
    
    /**
     * Fill area between charts.
     */
    func drawAreaBetweenLineCharts() {
        
        var xAxis = scaleDataXAxis(dataStore[0])
        var yAxisDataA = scaleDataYAxis(dataStore[areaBetweenLines[0]])
        var yAxisDataB = scaleDataYAxis(dataStore[areaBetweenLines[1]])
        var difference = yAxisDataA - yAxisDataB
        
        for index in 0..xAxis.count-1 {
            
            var context = UIGraphicsGetCurrentContext()
            
            if difference[index] < 0 {
                CGContextSetFillColorWithColor(context, negativeAreaColor.CGColor)
            } else {
                CGContextSetFillColorWithColor(context, positiveAreaColor.CGColor)
            }
            
            var point1XValue = xAxis[index] + axisInset
            var point1YValue = self.bounds.height - yAxisDataA[index] - axisInset
            var point2XValue = xAxis[index] + axisInset
            var point2YValue = self.bounds.height - yAxisDataB[index] - axisInset
            var point3XValue = xAxis[index+1] + axisInset
            var point3YValue = self.bounds.height - yAxisDataB[index+1] - axisInset
            var point4XValue = xAxis[index+1] + axisInset
            var point4YValue = self.bounds.height - yAxisDataA[index+1] - axisInset
            
            CGContextMoveToPoint(context, point1XValue, point1YValue)
            CGContextAddLineToPoint(context, point2XValue, point2YValue)
            CGContextAddLineToPoint(context, point3XValue, point3YValue)
            CGContextAddLineToPoint(context, point4XValue, point4YValue)
            CGContextAddLineToPoint(context, point1XValue, point1YValue)
            CGContextFillPath(context)
            
        }
        
    }
    
    
    
    /**
     * Draw x grid.
     */
    func drawXGrid() {
        var space = drawingWidth / numberOfGridLinesX
        var context = UIGraphicsGetCurrentContext()
        CGContextSetStrokeColorWithColor(context, gridColor.CGColor)
        for index in 1...numberOfGridLinesX {
            CGContextMoveToPoint(context, axisInset + (index * space), self.bounds.height - axisInset)
            CGContextAddLineToPoint(context, axisInset + (index * space), axisInset)
        }
        CGContextStrokePath(context)
    }
    
    
    
    /**
     * Draw y grid.
     */
    func drawYGrid() {
        var space = drawingHeight / numberOfGridLinesY
        var context = UIGraphicsGetCurrentContext()
        for index in 1...numberOfGridLinesY {
            CGContextMoveToPoint(context, axisInset, self.bounds.height - (index * space) - axisInset)
            CGContextAddLineToPoint(context, self.bounds.width - axisInset, self.bounds.height - (index * space) - axisInset)
        }
        CGContextStrokePath(context)
    }
    
    
    
    /**
     * Draw grid.
     */
    func drawGrid() {
        drawXGrid()
        drawYGrid()
    }
    
    
    
    /**
     * Add line chart
     */
    func addLine(data: Array<CGFloat>) {
        self.dataStore.append(data)
        self.setNeedsDisplay()
    }
    
}