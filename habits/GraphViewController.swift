//
//  GraphViewController.swift
//  habits
//
//  Created by Имангали on 12/28/22.
//

import UIKit
import Charts
import CoreData
import SwiftUI

class ItemForChart {
    var points: Int?
    var date: String?
    var index: Int
    init (index: Int, points: Int?, date: String?) {
        self.index = index
        self.points = points
        self.date = date
    }
    func transformToBarChartDataEntry() -> BarChartDataEntry {
        let entry = BarChartDataEntry(x: Double(index), y: Double(points!))
        return entry
    }
}

class GraphViewController: UIViewController, ChartViewDelegate {
    var historyTasks: [HistoryTasks] = []
    var lineChart = LineChartView()
    
    @IBOutlet weak var chartView: BarChartView!
    
    @IBAction func daysSegmentControl(_ daysSegmentControl: UISegmentedControl) {
        daysSegment.selectedSegmentIndex = daysSegmentControl.selectedSegmentIndex
        drawChart()
    }
    @IBOutlet weak var daysSegment: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lineChart.delegate = self
        
        renewData()
        drawChart()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        renewData()
        drawChart()
    }
    
    func getData() -> [ItemForChart] {
        var ans = [ItemForChart]()
        var c = 7
        if historyTasks.isEmpty == true {
            return ans
        }
        if daysSegment.selectedSegmentIndex == 0 {
            c = 7
        }
        else if daysSegment.selectedSegmentIndex == 1 {
            c = 30
        }
        else if daysSegment.selectedSegmentIndex == 2 {
            c = 1000
        }
        
        var currentDateTime = getCurrentDate()
        let stDate = historyTasks.map{$0.date ?? currentDateTime}.min()
        
        var cnt = 0
        
        while stDate! <= currentDateTime && cnt < c {
            
            if(cnt == 0) {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                let fetchRequest2: NSFetchRequest <Tasks> = Tasks.fetchRequest()
                do {
                    let tasks = try context.fetch(fetchRequest2)
                    var sum = 0
                    for task in tasks {
                        if task.done == false {
                            continue
                        }
                        sum += Int(task.points!)!
                    }
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "YY/MM/dd"
                    let newItem = ItemForChart(index: cnt, points: sum, date: dateFormatter.string(from: currentDateTime))
                    ans.append(newItem)
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
            }
            else {
                var x = historyTasks
                x = x.filter {$0.date == currentDateTime && $0.done == true}
                var sum = 0
                for i in x {
                    sum += Int(i.points!) ?? 0
                }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "YY/MM/dd"
                let newItem = ItemForChart(index: cnt, points: sum, date: dateFormatter.string(from: currentDateTime))
                ans.append(newItem)
            }
            currentDateTime = Calendar.current.date(byAdding: .day, value: -1, to: currentDateTime)!
            cnt += 1
        }
        
        for i in ans {
            i.index = cnt - i.index - 1
        }
        
        return ans
    }
    
    func drawChart() {
        var chartData = getData()
        for i in historyTasks {
            print(i)
        }
        let entries = chartData.map {$0.transformToBarChartDataEntry()}
        
        chartData.sort(by: {$0.index < $1.index})
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: chartData.map {$0.date!})
        chartView.xAxis.granularityEnabled = true
        chartView.leftAxis.axisMinimum = 0.0
        chartView.rightAxis.enabled = false
        let set = LineChartDataSet(entries: entries)
        set.colors = [NSUIColor.red]
        set.fillColor = UIColor.blue
        set.drawFilledEnabled = true
        
        let data = LineChartData(dataSet: set)
        chartView.data = data
        
    }
    func renewData() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest <HistoryTasks> = HistoryTasks.fetchRequest()
        
        fetchRequest.returnsObjectsAsFaults = false
        do {
            historyTasks = try context.fetch(fetchRequest)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        historyTasks = historyTasks.filter {$0.done == true}
    }
}
