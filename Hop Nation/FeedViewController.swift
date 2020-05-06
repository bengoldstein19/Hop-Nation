//
//  FeedViewController.swift
//  Hop Nation
//
//  Created by Ben Goldstein on 1/16/19.
//  Copyright © 2019 Benjamin Goldstein. All rights reserved.
//

import UIKit
import Kanna
import Alamofire
import SystemConfiguration

public class Reachability {
    
    class func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        // Only Working for WIFI
        let isReachable = flags == .reachable
        let needsConnection = flags == .connectionRequired
        
        return isReachable && !needsConnection
        
        // Working for Cellular and WIFI
        //        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        //        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        //        let ret = (isReachable && !needsConnection)
        //
        //        return ret
        
    }
}

protocol NewsCellDelegate {
    func callSegueFromCell(myData dataobject: Any)
    func addImage(image: UIImage, url: String)
    func getImage(url: String) -> UIImage
}

protocol ArticleVCDelegate {
    func getNext(sender: NewsCell)
    func getPrevious(sender: NewsCell)
}

class FeedViewController: UITableViewController, NewsCellDelegate, ArticleVCDelegate {
    func getPrevious(sender: NewsCell) {
        if sender != self.cells.first {
            let nextCell = self.cells[(self.cells.firstIndex(of: sender)?.advanced(by: -1))!]
            nextCell.initialize()
            nextCell.delegate.callSegueFromCell(myData: nextCell.getData())
        } else {
            let nextCell = self.cells[(self.cells.firstIndex(of: sender)?.advanced(by: 0))!]
            nextCell.initialize()
            nextCell.delegate.callSegueFromCell(myData: nextCell.getData())
        }
    }
    
    func doAlert() {
        let alert = UIAlertController(title: "No WIFI", message: "You are not connected to wifi. Refreshing may use a lot of cellular data. Are you sure you would like to continue?", preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)") // Prints true
                })
            }
            alert.dismiss(animated: true, completion: nil)
        }
        let retryAction = UIAlertAction(title: "Continue", style: .cancel) { (action) in
            self.getAllURLs()
            if !self.loading {
                self.toggleLoadingViews()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Change `2.0` to the desired number of seconds.
                self.refreshControl?.endRefreshing()
            }
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
    
    
    func getNext(sender: NewsCell) {
        if sender != self.cells.last {
            let nextCell = self.cells[(self.cells.firstIndex(of: sender)?.advanced(by: 1))!]
            nextCell.initialize()
            nextCell.delegate.callSegueFromCell(myData: nextCell.getData())
        } else {
            let nextCell = self.cells[(self.cells.firstIndex(of: sender)?.advanced(by: 0))!]
            nextCell.initialize()
            nextCell.delegate.callSegueFromCell(myData: nextCell.getData())
        }
    }
    
    @objc func scrollToTop() {
        self.tableView.scrollToRow(at: [0, 0], at: .top, animated: true)
    }
    
    func getImage(url: String) -> UIImage {
        if let im = imageDict[url] {
            return im
        }
        return UIImage(named: "default")!
    }
    
    func addImage(image: UIImage, url: String) {
        imageDict[url] = image
    }
    
    
    func callSegueFromCell(myData dataobject: Any) {
        self.performSegue(withIdentifier: "toArticle", sender:dataobject)
    }
    
    var imageDict = [String: UIImage]()
    var urls = [String]()
    var cells = [NewsCell]()
    var blockerview: UIView!
    var indicator: UIActivityIndicatorView!
    var loading: Bool!
    var loaderlabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl?.backgroundColor = UIColor(displayP3Red: 100/255, green: 0, blue: 0, alpha: 1)
        tableView.separatorStyle = .none
        navigationController?.navigationBar.barTintColor = UIColor(displayP3Red: 100/255, green: 0, blue: 0, alpha: 1)
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 1)]
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        var views = tabBarController?.tabBar.subviews.filter({$0.isUserInteractionEnabled})
        views?.sort(by: {$0.frame.minX < $1.frame.minX})
        let gestrec = UILongPressGestureRecognizer(target: self, action: #selector(scrollToTop))
        gestrec.minimumPressDuration = 0.1
        views!.first?.addGestureRecognizer(gestrec)
        loading = false
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
            self.getAllURLs()
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    func toggleLoadingViews() {
        if loading {
            indicator.removeFromSuperview()
            blockerview.removeFromSuperview()
            loaderlabel.removeFromSuperview()
            loading = false
        } else {
            self.view.addSubview(blockerview)
            self.view.addSubview(indicator)
            self.view.addSubview(loaderlabel)
            indicator.startAnimating()
            loading = true
        }
    }
    
    @objc func refresh() {
        if Reachability.isConnectedToNetwork() {
            getAllURLs()
            if !loading {
                toggleLoadingViews()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Change `2.0` to the desired number of seconds.
                self.refreshControl?.endRefreshing()
            }
        } else {
            doAlert()
        }
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
        // #warning Incomplete implementation, return the number of rows
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 410
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = cells[indexPath.row]
        return cell
        // Configure the cell...
    }
    
    func getCells(numrows: Int) {
        var urlstrs = [String]()
        cells = [NewsCell]()
        for i in 0..<numrows {
            var bool = false
            if let cell = self.tableView.dequeueReusableCell(withIdentifier: "newsCell") as? NewsCell {
                if !urlstrs.contains(urls[i]) {
                    cell.urlstring = "https://www.hopkins.edu" + urls[i]
                    urlstrs.append(urls[i])
                    cell.selectionStyle = .none
                    cell.delegate = self
                    cell.filled = false
                    if !cell.filled {
                        cell.initialize()
                        cell.articlePicture.image = UIImage(named: "default")
                    }
                    self.cells.append(cell)
                    bool = true
                }
            }
            if !bool {
                self.cells.append(NewsCell())
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            self.cells = self.cells.removeDuplicates()
            self.cells = self.cells.sorted(by: {(cell1, cell2) in
                if cell1.filled && cell2.filled {
                    if let cell1datestr = cell1.date, let cell2datestr = cell2.date {
                        let dateformatter = DateFormatter()
                        dateformatter.dateFormat = "M/d/y"
                        if let cell1date = dateformatter.date(from: cell1datestr), let cell2date = dateformatter.date(from: cell2datestr) {
                            return cell1date.timeIntervalSince(cell2date) > 0
                        } else {
                            return false
                        }
                    } else {
                        return false
                    }
                }
                return false
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if self.loading {
                    self.toggleLoadingViews()
                }
                self.tableView.reloadData()
            }
        }
    }
    
    
    func getAllURLs() {
        self.toggleLoadingViews()
        let formater = DateFormatter()
        formater.dateFormat = "M/d/y"
        let year = Calendar.current.component(.year, from: Date())
        print(year)
        let lastYear = year - 1
        let thisyrurlstr = "https://www.hopkins.edu/page/news-archive?YearNumber=\(year)&MonthNumber=&nc=0_9480"
        let lastyrurlstr = "https://www.hopkins.edu/page/news-archive?YearNumber=\(lastYear)&MonthNumber=&nc=0_9480"
        let thisyrhnurlstr = "https://www.hopkins.edu/page/news-archive?YearNumber=\(year)&MonthNumber=&nc=0_23063"
        let lastyrhnurlstr = "https://www.hopkins.edu/page/news-archive?YearNumber=\(lastYear)&MonthNumber=&nc=0_23063"
        getURLs(thisyrurlstr)
        getURLs(thisyrhnurlstr)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.getURLs(lastyrurlstr)
            self.getURLs(lastyrhnurlstr)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Change `2.0` to the desired number of seconds.
                self.getCells(numrows: self.urls.count)
            }
        }
    }
    
    func getURLs(_ url: String) {
        Alamofire.request(url).responseString { response in
            if let html = response.result.value {
                self.parseHTML(html: html)
            }
        }
    }
    
    func parseHTML(html: String) {
        if let doc = try? Kanna.HTML(html: html, encoding: String.Encoding.utf8) {
            let nodes = doc.xpath("//a")
            for node in nodes {
                if node.className?.lowercased().range(of: "button readmore") != nil {
                    if !self.urls.contains(node["href"]!) {
                        self.urls.append(node["href"]!)
                    }
                }
            }
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

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ArticleViewController {
            destination.data = sender as? [String : Any]
            destination.delegate = self
        }
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }

}

extension Array where Element:Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()
        
        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }
        
        return result
    }
}
