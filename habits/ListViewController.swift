//
//  ListViewController.swift
//  habits
//
//  Created by Имангали on 12/28/22.
//

import UIKit
import CoreData
func getCurrentDate() -> Date {
    let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    var currentDate = Calendar.current.date(from: components)
    currentDate =  Calendar.current.date(byAdding: .day, value: 2, to: currentDate!)
    return currentDate!
}
class ListViewController: UIViewController {
    var tasks: [Tasks] = []
    
    @IBOutlet weak var pointsToday: UILabel!
    
    @IBAction func addTask(_ sender: Any) {
        performSegue(withIdentifier: "newTask", sender: nil)
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func unwindToListViewController(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) {
        let sourceViewController = unwindSegue.source as! TaskViewController
        if unwindSegue.identifier == "unwindSave" {
            self.saveNewTask(title: sourceViewController.nameTextField.text!, points: sourceViewController.pointsTextField.text!, everyDay: (sourceViewController.everyDay.selectedSegmentIndex == 1))
            self.tableView.reloadData()
        }
    }
    
    func saveNewTask(title: String, points: String, everyDay: Bool) { // Saving New Task
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        guard let entity = NSEntityDescription.entity(forEntityName: "Tasks", in: context) else { return }
        let taskObject = Tasks(entity: entity, insertInto: context)
        
        taskObject.title = title
        taskObject.points = points
        taskObject.done = false
        taskObject.everyday = everyDay
        taskObject.date = getCurrentDate()
        
        do {
            try context.save()
            tasks.append(taskObject)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    
    func saveHistoryTasks(currentDate: Date) {
        for task in tasks {
            if task.date != currentDate {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                guard let entity = NSEntityDescription.entity(forEntityName: "HistoryTasks", in: context) else { return }
                let historyTaskObject = HistoryTasks(entity: entity, insertInto: context)
                historyTaskObject.title = task.title
                historyTaskObject.points = task.points
                historyTaskObject.date = task.date
                historyTaskObject.done = task.done
                do {
                    try context.save()
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
                if task.everyday == true {
                    task.date = currentDate
                    task.done = false
                }
                else {
                    if let index = tasks.firstIndex(where: {$0 == task}) {
                        tasks.remove(at: index)
                        context.delete(task)
                    }
                }
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest <Tasks> = Tasks.fetchRequest()
        fetchRequest.returnsObjectsAsFaults = false
        do {
            tasks = try context.fetch(fetchRequest)
            saveHistoryTasks(currentDate: getCurrentDate())
            try context.save()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        var sum = 0
        for task in tasks {
            if task.done == true {
                sum += Int(task.points!) ?? 0
            }
        }
        pointsToday.text = String(sum)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
}
extension ListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskTableViewCell
        let task = tasks[indexPath.row]
        cell.name.text = task.title
        cell.points.text = task.points
        if task.done == true {
            cell.backgroundColor = .systemCyan
            cell.name.textColor = .white
            cell.points.textColor = .white
            
        }
        else {
            cell.backgroundColor = .clear
            cell.name.textColor = .black
            cell.points.textColor = .black
        }
        return cell
    }
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let doneAction = UIContextualAction(style: .destructive, title: nil) { _, _, completion in
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest: NSFetchRequest <Tasks> = Tasks.fetchRequest()
            fetchRequest.returnsObjectsAsFaults = false
            if let tasks = try? context.fetch(fetchRequest) {
                let x = Int(self.pointsToday.text!) ?? 0
                var y = Int(tasks[indexPath.row].points!) ?? 0
                if tasks[indexPath.row].done == true {
                    y = -y
                }
                self.pointsToday.text = String(x + y)
                tasks[indexPath.row].done = !tasks[indexPath.row].done
            }
            do {
                try context.save()
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        doneAction.backgroundColor = .systemCyan
        if tasks[indexPath.row].done == true {
            doneAction.title = "Undo"
        }
        if tasks[indexPath.row].done == false {
            doneAction.title = "Done"
        }
        let config = UISwipeActionsConfiguration(actions: [doneAction])
        return config
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [self] _, _, completion in
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest: NSFetchRequest <Tasks> = Tasks.fetchRequest()
            
            
            if let tasks = try? context.fetch(fetchRequest) {
                if tasks[indexPath.row].done == true {
                    let x = Int(self.pointsToday.text!) ?? 0
                    let y = Int(tasks[indexPath.row].points!) ?? 0
                    self.pointsToday.text = String(x - y)
                }
                tasks[indexPath.row].done = !tasks[indexPath.row].done
                context.delete(tasks[indexPath.row])
            }
            self.tasks.remove(at: indexPath.row)
            do {
                try context.save()
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .systemRed
        
        let config = UISwipeActionsConfiguration(actions: [deleteAction])
        return config
        
    }
}
