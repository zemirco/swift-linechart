
import UIKit

class MainViewController: UIViewController, LineChartDelegate {

    var label = UILabel()
    
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
        
        
        var dataLineA: Array<CGFloat> = [3, 4, 9, 11, 13, 15]
        var dataLineB: Array<CGFloat> = [5, 4, 3, 6, 6, 7]
        
        var lineChart = LineChart(dataLineA: dataLineA, dataLineB: dataLineB)
        lineChart.setTranslatesAutoresizingMaskIntoConstraints(false)
        lineChart.delegate = self
        self.view.addSubview(lineChart)
        views["chart"] = lineChart
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[chart]-|", options: nil, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[label]-[chart(==200)]", options: nil, metrics: nil, views: views))
        
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    func didSelectDataPoint(x: CGFloat, yValueDataA: CGFloat, yValueDataB: CGFloat) {
        label.text = "x: \(x)     ya: \(yValueDataA)     yb: \(yValueDataB)"
    }

}
