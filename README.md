# Swift LineChart

<img src="https://s3.amazonaws.com/zeMirco/github/swift-linechart/gif.gif" alt="demo gif" style="width: 250px;">


## Usage

```swift
var dataLineA: Array<CGFloat> = [3, 4, 9, 11, 13, 15]
var dataLineB: Array<CGFloat> = [5, 4, 3, 6, 6, 7]

var lineChart = LineChart(dataLineA: dataLineA, dataLineB: dataLineB)
```

## Features

- Highly customizable
- Auto scaling
- Touch enabled
- Two-colored area between line charts

## Options

- `axesColor` x and y axis color.
- `dotsColor` small dots color.
- `dotsBackgroundColor` small dots background color.
- `lineWidth` line chart width.
- `lineAColor` line 1 color.
- `dotsAColor` dots on line 1 color.
- `lineBColor` line 2 color.
- `dotsBColor` dots on line 2 color.
- `positiveAreaColor` area chart color for `dataLineA` > `dataLineB`
- `negativeAreaColor` area chart color for `dataLineA` < `dataLineB`
- `maximumYValue` automatically set to highest value in `dataLineA` and `dataLineB`
- `axisInset` padding between outer view and chart axes


## Delegates

`didSelectDataPoint()`

Touch event happened at or close to data point.

```swift
func didSelectDataPoint(x: CGFloat, yValueDataA: CGFloat, yValueDataB: CGFloat) {
  println("\(x), \(yValueDataA), \(yValueDataB)")
}
```


## License

MIT
