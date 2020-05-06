//
//  HopScoresVC.swift
//  Hop Nation
//
//  Created by Ben Goldstein on 1/21/19.
//  Copyright © 2019 Benjamin Goldstein. All rights reserved.
//

import UIKit
import WebKit

class HopScoresVC: UIViewController, WKNavigationDelegate {
    
    var segmentedControl: UISegmentedControl!
    var webview: WKWebView!
    var btn: UIButton!
    var timer = Timer()
    var seconds: UInt32!
    let webContent = """
<a class="twitter-timeline" href="https://twitter.com/HopScores?ref_src=twsrc%5Etfw">Tweets by HopScores</a> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
"""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        segmentedControl = UISegmentedControl(items: ["Twitter", "Instagram"])
        let width = self.view.frame.width
        segmentedControl.frame = CGRect(origin: CGPoint(x: width/3, y: 100), size: CGSize(width: width/3, height: 40))
        segmentedControl.selectedSegmentIndex = 0
        webview = WKWebView(frame: CGRect(x: 0, y: 190, width: self.view.frame.width, height: self.view.frame.height - 210))
        webview.navigationDelegate = self
        segmentedControl.addTarget(self, action: #selector(updateView), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.tintColor = UIColor(displayP3Red: 100/255, green: 0, blue: 0, alpha: 1)
        var views = segmentedControl.subviews.filter({$0.isUserInteractionEnabled})
        views.sort(by: {$0.frame.minX < $1.frame.minX})
        btn = UIButton(type: .system)
        btn.frame = CGRect(x: width/3, y: 150, width: width/3, height: 50)
        webview.loadHTMLString(webContent, baseURL: nil)
        btn.setTitle("Refresh", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        btn.addTarget(self, action: #selector(reloadweb), for: .touchUpInside)
        startTimer()
        self.view.addSubview(webview)
        self.view.addSubview(segmentedControl)
        self.view.addSubview(btn)
        seconds = 0
        navigationController?.navigationBar.barTintColor = UIColor(displayP3Red: 100/255, green: 0, blue: 0, alpha: 1)
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 1)]
        // Do any additional setup after loading the view.
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
    }
    
    
    @objc func updateTimer() {
        btn.setTitle("Refresh", for: .normal)
        if segmentedControl.selectedSegmentIndex == 1 {
            let url = webview.url!
            if webview.url! != URL(string: "https://www.instagram.com/hopscoresct/feed/") && webview.url?.absoluteString.range(of: "/p/") == nil {
                let urlstring = "https://www.instagram.com/hopscoresct/feed/"
                let url = URL(string: urlstring)!
                let request = URLRequest(url: url)
                webview.load(request)
            } else if url.absoluteString.range(of: "/p/") != nil {
                self.btn.setTitle("Go Back", for: .normal)
            }
        }
    }

    
    @objc func reloadweb() {
        if segmentedControl.selectedSegmentIndex == 1 {
            let urlstring = "https://www.instagram.com/hopscoresct/feed/"
            let url = URL(string: urlstring)!
            let request = URLRequest(url: url)
            webview.load(request)
        } else {
            webview.loadHTMLString(webContent, baseURL: nil)
        }
    }
    
    @objc func updateView() {
        if segmentedControl.selectedSegmentIndex == 0 {
            webview.loadHTMLString(webContent, baseURL: nil)
            
        } else {
            let urlstring = "https://www.instagram.com/hopscoresct/feed/"
            let url = URL(string: urlstring)!
            let request = URLRequest(url: url)
            webview.load(request)
        }
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
