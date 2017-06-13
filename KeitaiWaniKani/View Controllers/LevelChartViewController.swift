//
//  LevelChartViewController.swift
//  AlliCrab
//
//  Copyright © 2016 Chris Laverty. All rights reserved.
//

import UIKit
//TODO:
//import Charts
import WaniKaniKit

private let SECONDS_PER_DAY = Double(60 * 60 * 24)

class LevelChartViewController: UIViewController {
    
    // MARK: - Properties
    
    var levelData: LevelData? {
        didSet { updateChartData() }
    }
    
    // MARK: - Outlets
    
//    @IBOutlet weak var chartView: HorizontalBarChartView!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        chartView.descriptionText = ""
//        chartView.highlightPerTapEnabled = false
//        chartView.highlightPerDragEnabled = false
//        chartView.noDataText = "No level data"
//        chartView.noDataTextDescription = "Level data has not yet been loaded from the WaniKani web site"
//        chartView.infoTextColor = ApplicationSettings.globalTintColor()
//        
//        let xAxis = chartView.xAxis
//        xAxis.labelFont = UIFont.preferredFont(forTextStyle: UIFontTextStyleCaption1)
//        xAxis.labelPosition = .bottom
//        xAxis.drawGridLinesEnabled = false
//        xAxis.setLabelsToSkip(0)
//        
//        let yAxis = chartView.leftAxis
//        yAxis.labelFont = UIFont.preferredFont(forTextStyle: UIFontTextStyleCaption1)
//        yAxis.valueFormatter = {
//            let formatter = NumberFormatter()
//            formatter.minimumFractionDigits = 0
//            formatter.maximumFractionDigits = 2
//            return formatter
//            }()
//        
//        chartView.rightAxis.enabled = false
//        chartView.legend.enabled = false
        
        updateChartData()
    }
    
    // MARK: - Update UI
    
    private func updateChartData() {
//        guard chartView != nil else { return }
//        
//        if !chartView.isEmpty() {
//            chartView.clear()
//        }
//        
//        guard let levelData = self.levelData else { return }
//        
//        let xVals = levelData.detail.map { "\($0.level)" }
//        let yVals = levelData.detail.enumerated().map { i, levelInfo -> BarChartDataEntry in
//            let duration = levelInfo.duration ?? -levelInfo.startDate.timeIntervalSinceNow
//            return BarChartDataEntry(value: duration / SECONDS_PER_DAY, xIndex: i, data: duration)
//        }
//        
//        let dataSet = BarChartDataSet(yVals: yVals, label: "Level Duration")
//        dataSet.valueFont = UIFont.preferredFont(forTextStyle: UIFontTextStyleBody)
//        dataSet.barSpace = 0.25
//        dataSet.setColor(ApplicationSettings.globalTintColor())
//        dataSet.valueFormatter = NSTimeIntervalNumberFormatter()
//        
//        let data = BarChartData(xVals: xVals, dataSets: [dataSet])
//        
//        chartView.data = data
    }
    
}

private class NSTimeIntervalNumberFormatter: NumberFormatter {
    let wrapped: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour]
        formatter.allowsFractionalUnits = true
        formatter.collapsesLargestUnit = true
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    override func string(from number: NSNumber) -> String? {
        return wrapped.string(from: number.doubleValue * SECONDS_PER_DAY)
    }
}
