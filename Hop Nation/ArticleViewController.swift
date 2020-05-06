//
//  ViewController.swift
//  Hop Nation
//
//  Created by Ben Goldstein on 1/16/19.
//  Copyright © 2019 Benjamin Goldstein. All rights reserved.
//

import UIKit
import WebKit

class ArticleViewController: UIViewController {

    var data: [String: Any]!
    var delegate: ArticleVCDelegate!
    
    @IBOutlet weak var viewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var briefLabel: UILabel!
    @IBOutlet weak var longLabel: UILabel!
    @IBOutlet weak var outerStackView: UIStackView!
    @IBOutlet weak var articlePicture: UIImageView!
    @IBOutlet weak var videoView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("RECEIVED DATA")
        print(data)
        titleLabel.text = data["title"] as? String
        authorLabel.text = data["author"] as? String
        dateLabel.text = data["date"] as? String
        briefLabel.text = data["brief"] as? String
        longLabel.text = chatProcessed(articleText: (data["long"] as? String)!)
        articlePicture.image = data["image"] as? UIImage
        getVideo(url: (data["videoURL"] as? String)!)
        if longLabel.text!.count > 50 {
            longLabel.sizeToFit()
            longLabel.frame = CGRect(origin: longLabel.frame.origin, size: CGSize(width: longLabel.frame.width, height: longLabel.frame.height + 50))
        } else {
            longLabel.frame = CGRect(x: longLabel.frame.minX, y: longLabel.frame.minY, width: longLabel.frame.width, height: 60)
        }
        let picheight = articlePicture.frame.size.height
        let labelheight = longLabel.frame.size.height
        let vidheight = videoView.frame.size.height + 100
        var stackheight = CGFloat()
        if briefLabel.text!.count > 0 {
            stackheight = CGFloat(265)
            briefLabel.isHidden = false
        } else {
            briefLabel.isHidden = true
            stackheight = CGFloat(165)
        }
        viewHeightConstraint.constant = picheight + labelheight + vidheight + stackheight
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(sharepressed))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fillNavBar()
        }
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func fillNavBar() {
        let upItem = UIBarButtonItem(barButtonSystemItem: .fastForward, target: self, action: #selector(nextArticle))
        let downItem = UIBarButtonItem(barButtonSystemItem: .rewind, target: self, action: #selector(previousArticle))
        let currentrite = navigationItem.rightBarButtonItem!
        navigationItem.setRightBarButtonItems([currentrite, upItem, downItem], animated: true)
    }
    
    @objc func nextArticle() {
        print("next")
        navigationController?.popViewController(animated: false)
        self.delegate.getNext(sender: self.data["sender"] as! NewsCell)
    }
    
    @objc func previousArticle() {
        print("previous")
        navigationController?.popViewController(animated: false)
        self.delegate.getPrevious(sender: self.data["sender"] as! NewsCell)
    }
    
    func chatProcessed(articleText: String) -> String {
        var newstr = articleText
        if self.titleLabel.text?.lowercased().range(of: "chat") != nil {
            var counter = 0
            var oldchar = Character(" ")
            var indexestoinsert = [Int]()
            for char in articleText {
                if (oldchar == "." || oldchar == "?" || oldchar == "!" || oldchar == "*") && char != "\n" && char != " " && !(char == "." || char == "?" || char == "!" || char == "*") {
                    indexestoinsert.append(counter)
                }
                oldchar = char
                counter = counter + 1
            }
            for index in indexestoinsert.reversed() {
                newstr.insert("\n", at: newstr.index(newstr.startIndex, offsetBy: index))
            }
        }
        return newstr
    }
    

    @objc func sharepressed() {
        let text = "Check out '\(self.titleLabel.text!)'!"
        let url = URL(string: (data["url"] as! String))
        let image = self.articlePicture.image
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [text, url, image], applicationActivities: nil)
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
    
    func getVideo(url: String) {
        var equalSignFound = false
        for char in url {
            if char == "=" {
                equalSignFound = true
                break
            }
        }
        if equalSignFound {
            let address = URL(string: url)
            let wkWebView = WKWebView(frame: CGRect(x: 0, y: 0, width: videoView.frame.size.width, height: videoView.frame.size.height), configuration: WKWebViewConfiguration())
            let youtubeRequest = URLRequest(url: address!)
            wkWebView.load(youtubeRequest)
            videoView.addSubview(wkWebView)
            print(videoView.subviews)
            videoView.isHidden = false
        } else {
            viewHeightConstraint.constant = viewHeightConstraint.constant - videoView.frame.size.height
            videoView.isHidden = true
        }
    }
    
    
}

