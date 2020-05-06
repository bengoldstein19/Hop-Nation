//
//  ScoresVC.swift
//  Hop Nation
//
//  Created by Ben Goldstein on 1/28/19.
//  Copyright © 2019 Benjamin Goldstein. All rights reserved.
//

import UIKit
import Kanna
import Alamofire
import SystemConfiguration

protocol ScoreCellDelegate {
    func shareArticle(cell: ScoreCell)
}

class ScoresVC: UITableViewController, ScoreCellDelegate {
    
    func doAlert() {
        let alert = UIAlertController(title: "No WIFI", message: "Please connect to wifi and try again. This app may use an immense amount of data", preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)") // Prints true
                })
            }
        }
        let retryAction = UIAlertAction(title: "Continue", style: .cancel) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(settingsAction)
        alert.addAction(retryAction)
        let topWindow: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
        topWindow?.rootViewController = UIViewController()
        topWindow?.windowLevel = UIWindow.Level.alert + 1
        topWindow?.makeKeyAndVisible()
        topWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    func shareArticle(cell: ScoreCell) {
        let text = "Check out Hopkins vs. \(cell.opponentLabel.text!) in \(cell.topicLabel.text!)!"
        let image = cell.myimage
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [text, image], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = (navigationItem.rightBarButtonItem?.customView)
        
        // This line remove the arrow of the popover to show in iPad
        activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.unknown
        activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
        
        // Anything you want to exclude
        activityViewController.excludedActivityTypes = [
            UIActivity.ActivityType.postToWeibo,
            UIActivity.ActivityType.print,
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.addToReadingList,
            UIActivity.ActivityType.postToFlickr,
            UIActivity.ActivityType.postToVimeo,
            UIActivity.ActivityType.postToTencentWeibo
        ]
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    
    var ids = [String]()
    var topics = [String]()
    var cells = [ScoreCell]()
    var season = String()
    var scoredicts = [String: String]()
    var gamecount: Int!
    var scores: Bool!
    var pastcells = [ScoreCell]()
    var futurecells = [ScoreCell]()
    var blockerview: UIView!
    var indicator: UIActivityIndicatorView!
    var loading: Bool!
    var loaderlabel: UILabel!
    var numcells: Int!

    override func viewDidLoad() {
        super.viewDidLoad()
        gamecount = 0
        numcells = 20
        refreshControl?.backgroundColor = UIColor(displayP3Red: 100/255, green: 0, blue: 0, alpha: 1)
        tableView.separatorStyle = .none
        navigationController?.navigationBar.barTintColor = UIColor(displayP3Red: 100/255, green: 0, blue: 0, alpha: 1)
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 1)]
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        var views = tabBarController?.tabBar.subviews.filter({$0.isUserInteractionEnabled})
        views?.sort(by: {$0.frame.minX < $1.frame.minX})
        let gestrec = UILongPressGestureRecognizer(target: self, action: #selector(scrollToTop))
        gestrec.minimumPressDuration = 0.1
        views![1].addGestureRecognizer(gestrec)
        let rightbarbutton = UIBarButtonItem(title: "Schedule", style: .plain, target: self, action: #selector(toggle))
        rightbarbutton.tintColor = .white
        navigationItem.rightBarButtonItem = rightbarbutton
        getSeason()
        loading = false
        scores = true
        blockerview = UIView(frame: self.view.frame)
        blockerview.backgroundColor = .white
        indicator = UIActivityIndicatorView(style: .whiteLarge)
        indicator.color = .gray
        indicator.center = blockerview.center
        indicator.hidesWhenStopped = true
        loaderlabel = UILabel(frame: CGRect(x: 20, y: self.view.frame.height/3, width: self.view.frame.width - 40, height: 40))
        loaderlabel.text = "Patience is a virtue..."
        loaderlabel.textColor = .black
        loaderlabel.font = UIFont(name: "System", size: 20)
        loaderlabel.textAlignment = .center
        if cells.count == 0 {
            self.getAllIDs()
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    func toggleLoadingViews() {
        if loading {
            print("removed")
            indicator.removeFromSuperview()
            blockerview.removeFromSuperview()
            loaderlabel.removeFromSuperview()
            loading = false
        } else {
            print("added")
            self.view.addSubview(blockerview)
            self.view.addSubview(indicator)
            self.view.addSubview(loaderlabel)
            indicator.startAnimating()
            loading = true
        }
    }
    
    @objc func toggle() {
        scores = !scores
        if navigationItem.rightBarButtonItem?.title == "Schedule" {
            navigationItem.rightBarButtonItem?.title = "Scores"
            navigationItem.title = "Schedule"
        } else {
            navigationItem.rightBarButtonItem?.title = "Schedule"
            navigationItem.title = "Scores"
        }
        self.tableView.reloadData()
//        toggleLoadingViews()
        perform(#selector(scrollToTop))
    }
    
    func scrapeScores(_ url: String) {
        gamecount = 0
        Alamofire.request(url).responseString { response in
            if let _ = response.result.value {
                Alamofire.request(url).responseString { response in
                    if let html = response.result.value {
                        self.parseScoreHTML(html: html, url: url)
                    }
                }
            }
        }
    }
    
    func parseScoreHTML(html: String, url: String) {
        if let doc = try? Kanna.HTML(html: html, encoding: String.Encoding.utf8) {
            let games = doc.css("div[class^='game']")
            let tempteamname = doc.css("h4[class='team-name']")
            let teamname = tempteamname.first!.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            for game in games {
                if let doc2 = try? Kanna.HTML(html: game.innerHTML!, encoding: String.Encoding.utf8) {
                    let oppnodes = doc2.css("div[class='schedule-opponent']")
                    for node in oppnodes {
                        scoredicts["opponent<\(String(describing: gamecount!))>"] = node.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        scoredicts["topic<\(String(describing: gamecount!))>"] = teamname
                    }
                    let nodes = doc2.css("span[class='schedule-date']")
                    let newnodes = nodes.dropLast(nodes.count/2)
                    var counter = 0
                    for _ in newnodes {
                        let currentnodes = [nodes[counter*2], nodes[counter*2 + 1]]
                        let node1str = currentnodes.first!.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        let node2str = currentnodes.last!.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        let allnodestr = "\(node1str) \(node2str)"
                        scoredicts["date<\(String(describing: gamecount!))>"] = allnodestr
                        counter = counter + 1
                    }
                    scoredicts["canceled<\(String(describing: gamecount!))>"] = "pizza"
                    for node in doc2.css("div[class='schedule-cancelled']") {
                        scoredicts["canceled<\(String(describing: gamecount!))>"] = node.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    }
                    for node in doc2.css("div[class='schedule-rescheduled']") {
                        scoredicts["canceled<\(String(describing: gamecount!))>"] = node.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    }
                    let scorenodes = doc2.css("span[class='score']")
                    for node in scorenodes {
                        scoredicts["score<\(String(describing: gamecount!))>"] = node.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    }
                }
                gamecount = gamecount + 1
            }
        }
    }
    
    func getSeason() {
        let year = Calendar.current.component(.year, from: Date().addingTimeInterval(30*24*5*3600))
        let lastyr = year - 1
        season = "\(lastyr)+-+\(year)"
    }
    
    func getCellID(data: [String: String]) -> String {
        if let topic = data["topic"], let date = data["date"] {
            return topic + date
        } else {
            return "potato"
        }
    }
    
    func getCells(numrows: Int) {
        cells.removeAll()
        var idstrs = [String]()
        var num = ""
        for i in 0..<numrows {
            if let cell = self.tableView.dequeueReusableCell(withIdentifier: "scoreCell") as? ScoreCell {
                var celldict = [String: String]()
                let tempkeys = scoredicts.keys.reversed().reversed().filter( { (string) in
                    return string.range(of: String(describing: i)) != nil
                })
                for key in tempkeys {
                    let start = key.lastIndex(of: "<")!
                    let end = key.lastIndex(of: ">")!
                    var index = key.index(start, offsetBy: 1)
                    num = ""
                    while key.index(index, offsetBy: 0) != end {
                        num = num + String(key[index])
                        index = key.index(index, offsetBy: 1)
                    }
                    if num == String(describing: i) {
                        var newkey = key
                        for _ in 0..<num.count + 2 {
                            newkey.remove(at: start)
                        }
                        celldict[newkey] = scoredicts[key]
                    }
                    if key == tempkeys.last {
                        let gottenid = getCellID(data: celldict)
                        if !idstrs.contains(gottenid) && gottenid != "potato" {
                            cell.selectionStyle = .none
                            cell.myDataDict = celldict
                            cell.fill()
                            cell.delegate = self
                            idstrs.append(getCellID(data: celldict))
                            self.cells.append(cell)
                        }
                        if i == numrows - 1 {
                            self.pastcells.removeAll()
                            self.futurecells.removeAll()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                for cell in self.cells {
                                    if let text = cell.dateLabel.text {
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "EEEE, M/d/y h:mm a"
                                        if let date = formatter.date(from: text) {
                                            if date.timeIntervalSince(Date()) > 12*60*60 {
                                                self.futurecells.append(cell)
                                            } else if date.timeIntervalSince(Date()) < -12*60*60{
                                                self.pastcells.append(cell)
                                            } else {
                                                self.futurecells.append(cell)
                                                self.pastcells.append(cell)
                                            }
                                        } else {
                                            formatter.dateFormat = "EEEE, M/d/y"
                                            if let date = formatter.date(from: text) {
                                                if date.timeIntervalSince(Date()) > 12*60*60 {
                                                    self.futurecells.append(cell)
                                                } else if date.timeIntervalSince(Date()) < -12*60*60{
                                                    self.pastcells.append(cell)
                                                } else {
                                                    self.futurecells.append(cell)
                                                    self.pastcells.append(cell)
                                                }
                                            }
                                        }
                                    }
                                    if cell == self.cells.last {
                                        self.pastcells.sort(by: {(scorecell1, scorecell2) in
                                            if let text1 = scorecell1.dateLabel.text, let text2 = scorecell2.dateLabel.text {
                                                let formatter = DateFormatter()
                                                formatter.dateFormat = "EEEE, M/d/y h:mm a"
                                                if let date1 = formatter.date(from: String(text1)) {
                                                    if let date2 = formatter.date(from: String(text2)) {
                                                        return Double((date1.timeIntervalSince(date2))) > 0.0
                                                    } else {
                                                        formatter.dateFormat = "EEEE, M/d/y"
                                                        if let date2 = formatter.date(from: String(text2)) {
                                                            return Double((date1.timeIntervalSince(date2))) > 0.0
                                                        }
                                                    }
                                                } else {
                                                    formatter.dateFormat = "EEEE, M/d/y"
                                                    if let date1 = formatter.date(from: String(text1)) {
                                                        formatter.dateFormat = "EEEE, M/d/y h:mm a"
                                                        if let date2 = formatter.date(from: String(text2)) {
                                                            return Double((date1.timeIntervalSince(date2))) > 0.0
                                                        } else {
                                                            formatter.dateFormat = "EEEE, M/d/y"
                                                            if let date2 = formatter.date(from: String(text2)) {
                                                                return Double((date1.timeIntervalSince(date2))) > 0.0
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            return true
                                        })
                                        self.futurecells.sort(by: {(scorecell1, scorecell2) in
                                            if let text1 = scorecell1.dateLabel.text, let text2 = scorecell2.dateLabel.text {
                                                let formatter = DateFormatter()
                                                formatter.dateFormat = "EEEE, M/d/y h:mm a"
                                                if let date1 = formatter.date(from: String(text1)) {
                                                    if let date2 = formatter.date(from: String(text2)) {
                                                        return Double((date1.timeIntervalSince(date2))) < 0.0
                                                    } else {
                                                        formatter.dateFormat = "EEEE, M/d/y"
                                                        if let date2 = formatter.date(from: String(text2)) {
                                                            return Double((date1.timeIntervalSince(date2))) < 0.0
                                                        }
                                                    }
                                                } else {
                                                    formatter.dateFormat = "EEEE, M/d/y"
                                                    if let date1 = formatter.date(from: String(text1)) {
                                                        formatter.dateFormat = "EEEE, M/d/y h:mm a"
                                                        if let date2 = formatter.date(from: String(text2)) {
                                                            return Double((date1.timeIntervalSince(date2))) < 0.0
                                                        } else {
                                                            formatter.dateFormat = "EEEE, M/d/y"
                                                            if let date2 = formatter.date(from: String(text2)) {
                                                                return Double((date1.timeIntervalSince(date2))) < 0.0
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            return false
                                        })
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                            print("table view reloaded")
                                            print(self.pastcells.count)
                                            print(self.futurecells.count)
                                            self.tableView.reloadData()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getData() {
        print("data gotten")
        for id in ids {
            let urlstr = "https://www.hopkins.edu/page/team-detail?fromId=221617&Team=\(id)&SeasonLabel=\(season)"
            scrapeScores(urlstr)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.getCells(numrows: self.gamecount)
        }
    }
    
    func getAllIDs() {
        if !loading {
            toggleLoadingViews()
        }
        print("ids gotten")
        ids.removeAll()
        getIDs("https://www.hopkins.edu/page/athletics/team-pages")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Change `2.0` to the desired number of seconds.
            self.getData()
        }
    }
    
    func getIDs(_ url: String) {
        print("id gotten")
        Alamofire.request(url).responseString { response in
            if let html = response.result.value {
                self.parseHTML(html: html)
            }
        }
    }
    
    func parseHTML(html: String) {
        print("html parsed")
        if let doc = try? Kanna.HTML(html: html, encoding: String.Encoding.utf8) {
            let nodes = doc.xpath("//option")
            for node in nodes {
                if !self.ids.contains(node["value"]!) && node["value"]!.count > 0 {
                    self.ids.append(node["value"]!)
                }
            }
        }
    }
    
    @objc func refresh() {
        if Reachability.isConnectedToNetwork() {
            self.getAllIDs()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.refreshControl?.endRefreshing()
            }
        } else {
            doAlert()
        }
    }
    
    @objc func scrollToTop() {
        self.tableView.scrollToRow(at: [0, 0], at: .top, animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
//            if self.pastcells.count == 0 {
//                self.refresh()
//            }
        if scores {
            print("pastcells.count")
            print(pastcells.count)
            return pastcells.count
        } else {
            print("futurecells.count")
            print(futurecells.count)
            return futurecells.count
        }
    }
    
    
    //uncomment to handle reaching of bottom
//    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let height = scrollView.frame.size.height
//        let contentYoffset = scrollView.contentOffset.y
//        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
//        if distanceFromBottom < height {
//            self.numcells = self.numcells + 20
//            self.tableView.reloadData()
//        }
//    }
    
    

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row > 5 {
                if self.loading {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.toggleLoadingViews()
                    }
                }
        }
        if scores {
            return pastcells[indexPath.row]
        } else {
            return futurecells[indexPath.row]
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
