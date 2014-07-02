
import UIKit
import QuartzCore

class MainViewController: UIViewController, LineChartDelegate {

    
    
    var label = UILabel()
    var lineChart: LineChart?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var views: Dictionary<String, AnyObject> = [:]
        
        label.text = "..."
        label.setTranslatesAutoresizingMaskIntoConstraints(false)
        label.textAlignment = NSTextAlignment.Center
        self.view.addSubview(label)
        views["label"] = label
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[label]-|", options: nil, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-80-[label]", options: nil, metrics: nil, views: views))
        
        var data: Array<CGFloat> = [3, 4, 9, 11, 13, 15]
        
        lineChart = LineChart()
        lineChart!.addLine(data)
        lineChart!.setTranslatesAutoresizingMaskIntoConstraints(false)
        lineChart!.delegate = self
        self.view.addSubview(lineChart)
        views["chart"] = lineChart
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[chart]-|", options: nil, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[label]-[chart(==200)]", options: nil, metrics: nil, views: views))
        
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    /**
     * Line chart delegate method.
     */
    func didSelectDataPoint(x: CGFloat, yValues: Array<CGFloat>) {
        label.text = "x: \(x)     y: \(yValues)"
    }
    
    
    
    /**
     * Redraw chart on device rotation.
     */
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        if let chart = lineChart {
            chart.setNeedsDisplay()
        }
    }

}
