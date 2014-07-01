


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
    func didSelectDataPoint(x: CGFloat, yValueDataA: CGFloat, yValueDataB: CGFloat)
}



// LineChart class
class LineChart: UIControl {
    
    
    
    // colors (from google ui color palette)
    
    // Blue Grey 500 - #607d8b
    var axesColor = UIColor(red: 96/255.0, green: 125/255.0, blue: 139/255.0, alpha: 1)
    var dotsColor = UIColor(red: 96/255.0, green: 125/255.0, blue: 139/255.0, alpha: 1)
    var dotsBackgroundColor = UIColor.whiteColor()
    
    var lineWidth: CGFloat = 4
    
    // Teal 500 - #009688
    var lineAColor = UIColor(red: 0/255.0, green: 150/255.0, blue: 136/255.0, alpha: 1)
    // Teal 700 - #00796b
    var dotsAColor = UIColor(red: 0/255.0, green: 121/255.0, blue: 107/255.0, alpha: 1)
    
    // Purple 500 - #9c27b0
    var lineBColor = UIColor(red: 156/255.0, green: 39/255.0, blue: 176/255.0, alpha: 1)
    // Purple 700 - #7b1fa2
    var dotsBColor = UIColor(red: 123/255.0, green: 31/255.0, blue: 162/255.0, alpha: 1)
    
    // Red 200 - #f69988
    var positiveAreaColor = UIColor(red: 246/255.0, green: 153/255.0, blue: 136/255.0, alpha: 1)
    
    // Green 200 - #72d572
    var negativeAreaColor = UIColor(red: 114/255.0, green: 213/255.0, blue: 114/255.0, alpha: 1)
    
    
    
    // sizes
    
    // space between axis and view border
    var axisInset: CGFloat = 10
    
    // height and width for drawing data area
    var drawingHeight: CGFloat = 0
    var drawingWidth: CGFloat = 0
    
    var maximumYValue: CGFloat = 1
    
    var dataLineA: Array<CGFloat> = []
    var dataLineB: Array<CGFloat> = []
    
    var dotsDataA: Array<CALayer> = []
    var dotsDataB: Array<CALayer> = []
    
    var delegate: LineChartDelegate?
    
    
    
    init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
    }
    
    
    
    convenience init(dataLineA: Array<CGFloat>, dataLineB: Array<CGFloat>) {
        self.init(frame: CGRectZero)
        self.dataLineA = dataLineA
        self.dataLineB = dataLineB
        self.maximumYValue = getMaximumValue(dataLineA, dataLineB: dataLineB)
    }
    
    
    
    override func drawRect(rect: CGRect) {
        
        self.drawingHeight = self.bounds.height - (2 * axisInset)
        self.drawingWidth = self.bounds.width - (2 * axisInset)
        
        // draw axes
        drawAxes()
        
        // line A
        var scaledDataLineAXAxis = scaleDataXAxis(dataLineA)
        var scaledDataLineAYAxis = scaleDataYAxis(dataLineA)
        drawLine(scaledDataLineAXAxis, yAxis: scaledDataLineAYAxis, dataIdentifier: "A")
        drawDataDots(scaledDataLineAXAxis, yAxis: scaledDataLineAYAxis, dataIdentifier: "A")
        
        // line B
        var scaledDataLineBXAxis = scaleDataXAxis(dataLineB)
        var scaledDataLineBYAxis = scaleDataYAxis(dataLineB)
        drawLine(scaledDataLineBXAxis, yAxis: scaledDataLineBYAxis, dataIdentifier: "B")
        drawDataDots(scaledDataLineBXAxis, yAxis: scaledDataLineBYAxis, dataIdentifier: "B")
        
        // draw area chart
        drawAreaBetweenLineCharts(scaledDataLineAXAxis, yAxisDataA: scaledDataLineAYAxis, yAxisDataB: scaledDataLineBYAxis)
    }
    
    
    
    /**
     * Get y value for given x value. Or return zero or maximum value.
     */
    func getYValueForXValue(x: CGFloat, data: Array<CGFloat>) -> CGFloat {
        if x < 0 {
            return data[0]
        } else if Int(x) > data.count - 1 {
            return data[data.count - 1]
        } else {
            return data[Int(x)]
        }
    }
    
    
    
    /**
     * Handle touch events.
     */
    func handleTouchEvents(touches: NSSet!, event: UIEvent!) {
        var point: AnyObject! = touches.anyObject()
        var xValue = point.locationInView(self).x
        var closestXValueIndex = findClosestXValueInData(xValue)
        var yValueDataA = getYValueForXValue(CGFloat(closestXValueIndex), data: dataLineA)
        var yValueDataB = getYValueForXValue(CGFloat(closestXValueIndex), data: dataLineB)
        highlightDataPoint(closestXValueIndex)
        delegate?.didSelectDataPoint(CGFloat(closestXValueIndex), yValueDataA: yValueDataA, yValueDataB: yValueDataB)
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
        var scaledDataXAxis = scaleDataXAxis(dataLineA)
        var difference = scaledDataXAxis[1] - scaledDataXAxis[0]
        var dividend = (xValue - axisInset) / difference
        var roundedDividend = Int(round(Double(dividend)))
        return roundedDividend
    }
    
    
    
    /**
     * Highlight data points at index.
     */
    func highlightDataPoint(index: Int) {
        // make all white again
        for index in 0..dotsDataA.count {
            dotsDataA[index].backgroundColor = dotsBackgroundColor.CGColor
            dotsDataB[index].backgroundColor = dotsBackgroundColor.CGColor
        }
        // highlight current data point
        var dotALayer: CALayer
        var dotBLayer: CALayer
        if index < 0 {
            dotALayer = dotsDataA[0]
            dotBLayer = dotsDataB[0]
        } else if index > dotsDataA.count - 1 {
            dotALayer = dotsDataA[dotsDataA.count - 1]
            dotBLayer = dotsDataB[dotsDataB.count - 1]
        } else {
            dotALayer = dotsDataA[index]
            dotBLayer = dotsDataB[index]
        }
        dotALayer.backgroundColor = dotsAColor.CGColor
        dotBLayer.backgroundColor = dotsBColor.CGColor
    }
    
    
    
    /**
     * Draw small dot at every data point.
     */
    func drawDataDots(xAxis: Array<CGFloat>, yAxis: Array<CGFloat>, dataIdentifier: String) {
        var size: CGFloat = 12
        for index in 0..xAxis.count {
            var xValue = xAxis[index] + axisInset - size/2
            var yValue = self.bounds.height - yAxis[index] - axisInset - size/2
            
            // draw white layer
            var whiteLayer = CALayer()
            whiteLayer.backgroundColor = dotsBackgroundColor.CGColor
            whiteLayer.cornerRadius = size / 2
            whiteLayer.frame = CGRect(x: xValue, y: yValue, width: size, height: size)
            
            // draw black layer on top because just using one layer causes weird border issues
            var borderWidth: CGFloat = 4
            var blackLayerSize = size - borderWidth
            var blackLayer = CALayer()
            blackLayer.backgroundColor = dotsColor.CGColor
            blackLayer.cornerRadius = blackLayerSize / 2
            blackLayer.frame = CGRect(x: xValue + (borderWidth/2), y: yValue + (borderWidth/2), width: blackLayerSize, height: blackLayerSize)
            
            // add both layers to view
            self.layer.addSublayer(whiteLayer)
            self.layer.addSublayer(blackLayer)
            if dataIdentifier == "A" {
                dotsDataA.append(whiteLayer)
            } else if dataIdentifier == "B" {
                dotsDataB.append(whiteLayer)
            }
        }
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
     * Get maximum value in both Arrays.
     */
    func getMaximumValue(dataLineA: Array<CGFloat>, dataLineB: Array<CGFloat>) -> CGFloat {
        var dataLine1Maximum = dataLineA.reduce(Int.min, { max(Int($0), Int($1)) })
        var dataLine2Maximum = dataLineB.reduce(Int.min, { max(Int($0), Int($1)) })
        if dataLine1Maximum >= dataLine2Maximum {
            return CGFloat(dataLine1Maximum)
        } else {
            return CGFloat(dataLine2Maximum)
        }
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
    func drawLine(xAxis: Array<CGFloat>, yAxis: Array<CGFloat>, dataIdentifier: String) {
        var context = UIGraphicsGetCurrentContext()
        CGContextSetLineWidth(context, lineWidth)
        if dataIdentifier == "A" {
            CGContextSetStrokeColorWithColor(context, lineAColor.CGColor)
        } else if dataIdentifier == "B" {
            CGContextSetStrokeColorWithColor(context, lineBColor.CGColor)
        }
        // move to first data point
        CGContextMoveToPoint(context, axisInset, self.bounds.height - yAxis[0] - axisInset)
        // draw lines to rest of data points
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
    func drawAreaBetweenLineCharts(xAxis: Array<CGFloat>, yAxisDataA: Array<CGFloat>, yAxisDataB: Array<CGFloat>) {
        
        // calculate difference between y values
        var difference = yAxisDataA - yAxisDataB
        
        // draw graph in sections
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
            
            // draw section
            CGContextMoveToPoint(context, point1XValue, point1YValue)
            CGContextAddLineToPoint(context, point2XValue, point2YValue)
            CGContextAddLineToPoint(context, point3XValue, point3YValue)
            CGContextAddLineToPoint(context, point4XValue, point4YValue)
            CGContextAddLineToPoint(context, point1XValue, point1YValue)
            
            CGContextFillPath(context)
            
        }
        
    }
    
}