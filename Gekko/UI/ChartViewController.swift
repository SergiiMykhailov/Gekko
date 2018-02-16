//  Created by Sergii Mykhailov on 05/12/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation
import SwiftCharts
import SnapKit

protocol ChartViewControllerDataSource : class {

    func dataForChartViewController(sender:ChartViewController) -> [CandleInfo]

}

class ChartViewController : UIViewController {

    // MARK: Public functions and properties

    public weak var dataSource:ChartViewControllerDataSource?

    public func reloadData() {
        if (dataSource == nil) {
            chart?.clearView()
            return
        }

        let chartData = dataSource?.dataForChartViewController(sender:self)

        chartPoints.removeAll()
        for candleInfo in chartData! {
            let itemToInsert = candleStickFrom(candleInfo:candleInfo)
            chartPoints.append(itemToInsert)
        }

        setupChartView()
    }

    // MARK: Overriden methods

    override func viewDidLoad() {
        super.viewDidLoad()

        formatter.dateFormat = "MMM dd"

        reloadData()
    }

    // MARK: Internal

    fileprivate func setupChartView() {
        let labelSettings = ChartLabelSettings(font:UIFont.systemFont(ofSize:8))

        let minMaxValues = minMaxTradingValues()

        if minMaxValues.minValue == nil {
            // No data available. Just return.
            return
        }

        let yValues = stride(from:minMaxValues.minValue!,
                             through:minMaxValues.maxValue!,
                             by:minMaxValues.maxValue! / 10).map {ChartAxisValueDouble(Double($0),
                                                                 labelSettings:labelSettings)}

        let xGeneratorDate = ChartAxisValuesGeneratorDate(unit:.day, preferredDividers:7, minSpace:1, maxTextSize:8)
        let xLabelGeneratorDate = ChartAxisLabelsGeneratorDate(labelSettings:labelSettings,
                                                               formatter:formatter)
        let firstDate = chartPoints[0].date
        let lastDate = chartPoints.last!.date
        let xModel = ChartAxisModel(firstModelValue:firstDate.timeIntervalSince1970,
                                    lastModelValue:lastDate.timeIntervalSince1970,
                                    axisTitleLabels:[ChartAxisLabel](),
                                    axisValuesGenerator:xGeneratorDate,
                                    labelsGenerator:xLabelGeneratorDate)

        let yModel = ChartAxisModel(axisValues:yValues)
        let chartFrame = self.view.bounds
        let chartSettings = ChartViewController.chartSettings

        let coordsSpace = ChartCoordsSpaceRightBottomSingleAxis(chartSettings:chartSettings,
                                                                chartFrame:chartFrame,
                                                                xModel:xModel,
                                                                yModel:yModel)
        let (xAxisLayer, yAxisLayer, innerFrame) = (coordsSpace.xAxisLayer,
                                                    coordsSpace.yAxisLayer,
                                                    coordsSpace.chartInnerFrame)

        let chartPointsLineLayer = ChartCandleStickLayer<ChartPointCandleStick>(xAxis:xAxisLayer.axis,
                                                                                yAxis:yAxisLayer.axis,
                                                                                chartPoints:chartPoints,
                                                                                itemWidth:7,
                                                                                strokeWidth:0.6,
                                                                                increasingColor:UIDefaults.GreenColor,
                                                                                decreasingColor:UIDefaults.RedColor)

        let settings = ChartGuideLinesLayerSettings(linesColor:UIDefaults.SeparatorColor,
                                                    linesWidth:0.5)
        let guidelinesLayer = ChartGuideLinesLayer(xAxisLayer:xAxisLayer,
                                                   yAxisLayer:yAxisLayer,
                                                   settings:settings)

        let chart = Chart(
            frame: chartFrame,
            innerFrame: innerFrame,
            settings: chartSettings,
            layers: [
                xAxisLayer,
                yAxisLayer,
                guidelinesLayer,
                chartPointsLineLayer
            ]
        )

        view.backgroundColor = UIColor.white
        view.contentMode = .redraw
        view.addSubview(chart.view)

        chart.view.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
        }

        self.chart?.view.removeFromSuperview()
        self.chart = chart
    }

    fileprivate func candleStickFrom(candleInfo:CandleInfo) -> ChartPointCandleStick {
        return ChartPointCandleStick(date:candleInfo.date,
                                     formatter:self.formatter,
                                     high:candleInfo.high,
                                     low:candleInfo.low,
                                     open:candleInfo.open,
                                     close:candleInfo.close)
    }

    fileprivate func minMaxTradingValues() -> (minValue:Double?, maxValue:Double?) {
        if dataSource == nil {
            return (nil, nil)
        }

        let chartCandles = dataSource!.dataForChartViewController(sender:self)
        if chartCandles.isEmpty {
            return (nil, nil)
        }

        var minValue = Double.greatestFiniteMagnitude
        var maxValue = -Double.greatestFiniteMagnitude

        for chartCandle in chartCandles {
            minValue = min(minValue, chartCandle.low)
            maxValue = max(maxValue, chartCandle.high)
        }

        let closestValuePair = closestValue(forValue:minValue, greaterThan:false)
        minValue = closestValuePair.value

        maxValue += closestValuePair.comparableValue
        maxValue = round(maxValue / closestValuePair.comparableValue) * closestValuePair.comparableValue

        return (minValue, maxValue)
    }

    fileprivate func closestValue(forValue value:Double,
                                  greaterThan:Bool) -> (value:Double, comparableValue:Double) {
        var decimalItemsCount = 0
        var comparableValue = pow(Double(10), Double(decimalItemsCount))
        while value > comparableValue {
            decimalItemsCount += 1
            comparableValue = pow(Double(10), Double(decimalItemsCount))
        }

        decimalItemsCount -= 2
        comparableValue = pow(Double(10), Double(decimalItemsCount))

        var closestValue = value / comparableValue

        if greaterThan {
            closestValue += 1
        }

        closestValue = Double(Int(closestValue)) // Cut out digits after floating point
        closestValue *= comparableValue

        return (closestValue, comparableValue)
    }

    fileprivate static var chartSettings:ChartSettings {
        var chartSettings = ChartSettings()
        chartSettings.leading = UIDefaults.SpacingSmall
        chartSettings.top = UIDefaults.Spacing
        chartSettings.trailing = 0
        chartSettings.bottom = 0
        chartSettings.labelsToAxisSpacingX = 4
        chartSettings.labelsToAxisSpacingY = 4
        chartSettings.axisTitleLabelsToLabelsSpacing = 4
        chartSettings.axisStrokeWidth = 0.05
        chartSettings.spacingBetweenAxesX = UIDefaults.SpacingSmall
        chartSettings.spacingBetweenAxesY = UIDefaults.SpacingSmall
        chartSettings.labelsSpacing = 0
        chartSettings.zoomPan.panEnabled = true
        chartSettings.zoomPan.zoomEnabled = true
        return chartSettings
    }

    // MARK: Internal fields

    fileprivate var chart:Chart?
    fileprivate var formatter = DateFormatter()
    fileprivate var chartPoints = [ChartPointCandleStick]()
}
