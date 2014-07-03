# Swift LineChart

![line chart demo](https://s3.amazonaws.com/zeMirco/github/swift-linechart/gif30.gif)

## Usage

```swift
var lineChart = LineChart()
lineChart.addLine([3, 4, 9, 11, 13, 15])
```

## Features

- Super simple
- Highly customizable
- Auto scaling
- Touch enabled
- Two-colored area between line charts

## Properties

- `gridVisible` Show or hide grid. Default `true`.
- `axesVisible` Show or hide x and y axes. Default `true`.
- `dotsVisible` Show tiny dots at data points. Default `true`.
- `labelsXVisible` Show labels on x axis. Default `false`.
- `labelsYVisible` Show labels on y axis. Default `false`.
- `numberOfGridLinesX` Number of grid lines in horizontal direction. Default `10`.
- `numberOfGridLinesY` Number of grid lines in vertical direction. Default `10`.
- `animationEnabled` Draw line and dots with animation. Default `true`.
- `animationDuration` Animation duration. Default `1`.
- `dotsBackgroundColor` Tiny dots background color. Default white.
- `gridColor` Grid color. Default light grey.
- `axesColor` Axes color. Default grey.
- `positiveAreaColor` Filled area color when line A > line B. Default light green.
- `negativeAreaColor` Filled area color when line A < line B. Default light red.
- `areaBetweenLines` Draw filled area between lines with those two indexes. Default `[-1, -1]`
- `lineWidth` Line width. Default `2`.
- `dotsSize` Dot size. Default `12`.
- `dotsBorderWidth` Dot border width. Default `4`.
- `axisInset` Padding between view border and chart axes. Default `10`.

## Methods

Add line to chart.

`lineChart.addLine(data: Array<CGFloat>)`

## Delegates

`didSelectDataPoint()`

Touch event happened at or close to data point.

```swift
func didSelectDataPoint(x: CGFloat, yValues: Array<CGFloat>) {
  println("\(x) and \(yValues)")
}
```

## Examples

#### Single line with default settings.

![line chart demo](https://s3.amazonaws.com/zeMirco/github/swift-linechart/01.png)

```swift
var lineChart = LineChart()
lineChart.addLine([3, 4, 9, 11, 13, 15])
```

#### Two lines without grid and dots.

![two lines without grid and dots](https://s3.amazonaws.com/zeMirco/github/swift-linechart/02.png)

```swift
var lineChart = LineChart()
lineChart.gridVisible = false
lineChart.dotsVisible = false
lineChart.addLine([3, 4, 9, 11, 13, 15])
lineChart.addLine([5, 4, 3, 6, 6, 7])
```

#### Area with positive and negative values between two line charts.

![area between two lines](https://s3.amazonaws.com/zeMirco/github/swift-linechart/03.png)

```swift
var lineChart = LineChart()
lineChart.dotsVisible = false
lineChart.addLine([3, 4, 9, 11, 13, 15])
lineChart.addLine([5, 4, 3, 6, 6, 7])
lineChart.areaBetweenLines = [0, 1]
```

#### Show x and y axis

![chart with x and y axis](https://s3.amazonaws.com/zeMirco/github/swift-linechart/04.png)

```swift
var lineChart = LineChart()
lineChart.addLine([3, 4, 9, 11, 13, 15])
lineChart.addLine([5, 4, 3, 6, 6, 7])
lineChart.axisInset = 20
lineChart.labelsXVisible = true
lineChart.numberOfGridLinesX = 5
lineChart.labelsYVisible = true
lineChart.numberOfGridLinesY = 5
```


## License

MIT
