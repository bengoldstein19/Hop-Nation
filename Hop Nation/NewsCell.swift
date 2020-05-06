//
//  NewsCell.swift
//  Hop Nation
//
//  Created by Ben Goldstein on 1/16/19.
//  Copyright © 2019 Benjamin Goldstein. All rights reserved.
//

import UIKit
import Alamofire
import Kanna

class NewsCell: UITableViewCell {
    
    @IBOutlet weak var topicLabel: UILabel!
    @IBOutlet weak var topicThumbnail: UIImageView!
    @IBOutlet weak var articlePicture: UIImageView!
    @IBOutlet weak var articleTitle: UILabel!
    @IBOutlet weak var articleView: ArticleView!
    @IBOutlet weak var stackView: UIStackView!
    
    var searchval: Double!
    var filled: Bool!
    var selectedView: UIView!
    var author: String!
    var title: String!
    var date: String!
    var brief: String!
    var long: String!
    var imgurl: String!
    var topic: String!
    var urlstring: String!
    var vidurl: String!
    var delegate: NewsCellDelegate!
    var indicator: UIActivityIndicatorView!

    override func awakeFromNib() {
        super.awakeFromNib()
        indicator = UIActivityIndicatorView()
        indicator.style = .gray
        indicator.center = self.contentView.center
        indicator.hidesWhenStopped = true
        self.contentView.addSubview(indicator)
        selectedView = UIView()
        selectedView.frame = self.articleView.frame
        selectedView.backgroundColor = .black
        selectedView.alpha = 0.2
        selectedView.center = articleView.center
        selectedView.clipsToBounds = true
        selectedView.cornerRadius1 = 8
        searchval = 0
        // Initialization code
    }
    
    func initialize() {
        if !filled {
            scrapeArticleData(url: urlstring)
            stackView.isUserInteractionEnabled = true
            let touchDown = UILongPressGestureRecognizer(target:self, action: #selector(didTouchDown))
            touchDown.minimumPressDuration = 0.05
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Change `2.0` to the desired number of seconds.
                self.articleView.addGestureRecognizer(touchDown)
                self.filled = true
            }
        }
        
    }
    
    @objc func didTouchDown(gesture: UILongPressGestureRecognizer) {
        
        if gesture.state == UIGestureRecognizer.State.began {
            self.contentView.addSubview(selectedView)
            selectedView.translatesAutoresizingMaskIntoConstraints = false
            selectedView.topAnchor.constraint(equalTo: articleView.safeAreaLayoutGuide.topAnchor).isActive = true
            selectedView.bottomAnchor.constraint(equalTo: articleView.safeAreaLayoutGuide.bottomAnchor).isActive = true
            selectedView.widthAnchor.constraint(equalToConstant: articleView.frame.size.width).isActive = true
            selectedView.centerXAnchor.constraint(equalTo: articleView.safeAreaLayoutGuide.centerXAnchor).isActive = true
        }
        if gesture.state == UIGestureRecognizer.State.ended {
            selectedView.removeFromSuperview()
            if self.articlePicture.image != nil {
                var data = [String: Any]()
                data["title"] = title
                data["author"] = author
                data["date"] = date
                data["brief"] = brief
                data["long"] = long
                data["image"] = articlePicture.image
                data["url"] = urlstring
                data["videoURL"] = vidurl
                data["imgurl"] = imgurl
                data["sender"] = self
                print(data)
                if (data["title"] as? String)!.count > 0 && (data["long"] as? String)!.count > 0 {
                    delegate.callSegueFromCell(myData: data)
                } else {
                    self.initialize()
                }
            } else {
                self.fillCell()
            }
        }
    }
    
    func getData() -> [String: Any] {
        var data = [String: Any]()
        data["title"] = title
        data["author"] = author
        data["date"] = date
        data["brief"] = brief
        data["long"] = long
        data["image"] = articlePicture.image
        data["url"] = urlstring
        data["videoURL"] = vidurl
        data["imgurl"] = imgurl
        data["sender"] = self
        return data
    }
    
    func getTopic(text: String) -> String {
        let topics = ["Cross Country", "Field Hockey", "Football", "Soccer", "Volleyball", "Water Polo", "Basketball", "Fencing", "Track", "Ski Team", "Squash", "Swim", "Wrestling", "Baseball", "Crew", "Golf", "Lacrosse", "Softball", "Tennis"]
        var record = 1
        var bestTopic = ""
        for topic in topics {
            let frequency = text.lowercased().components(separatedBy: topic.lowercased()).count
            if frequency > record {
                record = frequency
                bestTopic = topic
            }
        }
        return bestTopic
    }
    
    func isEqualTo(otherCell: NewsCell) -> Bool {
        if self.title == otherCell.title && self.date == otherCell.date {
            return true
        }
        return false
    }
    
    func fillCell() {
        print("\(title!) cell filled")
        self.articleTitle.text = self.title
        let topic = self.getTopic(text: self.long)
        self.topicLabel.text = topic.uppercased()
        if topicLabel.text!.count == 0 {
            self.topicLabel.text = "Athletics".uppercased()
            topicThumbnail.image = UIImage(named: "Hop")
        } else {
            topicThumbnail.image = UIImage(named: topic)
        }
        if self.imgurl != "cheddar" {
            let newim = self.articlePicture.dowloadFromServer(link: self.imgurl, contentMode: .scaleAspectFill)
            self.delegate.addImage(image: newim, url: self.imgurl)
        }
    }
    
    
    
    func scrapeArticleData(url: String) {
        Alamofire.request(url).responseString { response in
            if let html = response.result.value {
                self.parseHTML(html: html)
            }
        }
    }
    
    func parseHTML(html: String) {
        self.author = ""
        self.title = ""
        self.date = ""
        self.brief = ""
        self.long = ""
        self.imgurl = "cheddar"
        self.topic = ""
        self.vidurl = ""
        if let doc = try? Kanna.HTML(html: html, encoding: String.Encoding.utf8) {
            
            // Search for nodes by CSS selector
            let title_ = doc.at_css("h4")
                
            // Strip the string of surrounding whitespace.
            var showString = title_!.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            // All text involving shows on this page currently start with the weekday.
            // Weekday formatting is inconsistent, but the first three letters are always there.
            var regex = try! NSRegularExpression(pattern: " ", options: [.caseInsensitive])
            
            if regex.firstMatch(in: showString, options: [], range: NSMakeRange(0, showString.count)) != nil {
                self.title = showString
            }
            let author_ = doc.at_css("div[class^='author']")
                
            // Strip the string of surrounding whitespace.
            showString = author_!.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            // All text involving shows on this page currently start with the weekday.
            // Weekday formatting is inconsistent, but the first three letters are always there.
            regex = try! NSRegularExpression(pattern: " ", options: [.caseInsensitive])
                
            if regex.firstMatch(in: showString, options: [], range: NSMakeRange(0, showString.count)) != nil {
                self.author = showString
            }
            let date_ = doc.at_css("time")
                
            // Strip the string of surrounding whitespace.
            showString = date_!.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            // All text involving shows on this page currently start with the weekday.
            // Weekday formatting is inconsistent, but the first three letters are always there.
            regex = try! NSRegularExpression(pattern: "/", options: [.caseInsensitive])
            
            if regex.firstMatch(in: showString, options: [], range: NSMakeRange(0, showString.count)) != nil {
                self.date = showString
            }
            let briefDescription_ = doc.at_css("div[class='brief-description']")
                
            // Strip the string of surrounding whitespace.
            showString = briefDescription_!.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            // All text involving shows on this page currently start with the weekday.
            // Weekday formatting is inconsistent, but the first three letters are always there.
            regex = try! NSRegularExpression(pattern: " ", options: [.caseInsensitive])
            
            if regex.firstMatch(in: showString, options: [], range: NSMakeRange(0, showString.count)) != nil {
                self.brief = showString
            }
            let description_ = doc.at_css("div[class='description']")
                
            // Strip the string of surrounding whitespace.
            showString = description_!.text!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            // All text involving shows on this page currently start with the weekday.
            // Weekday formatting is inconsistent, but the first three letters are always there.
            regex = try! NSRegularExpression(pattern: " ", options: [.caseInsensitive])
            
            if regex.firstMatch(in: showString, options: [], range: NSMakeRange(0, showString.count)) != nil {
                self.long = showString
            }
            for image_ in doc.css("div[id$='325866'] > div > div > ul > li > ul > li > figure > div > noscript > img") {
                self.imgurl = "http:" + image_["src"]!
            }
            for vid in doc.css("iframe") {
                self.vidurl = vid["src"]!
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Change `2.0` to the desired number of seconds.
                self.fillCell()
            }
        }
    }
    
}

extension UIImageView {
    func dowloadFromServer(url: URL, contentMode mode: UIView.ContentMode = .center) -> UIImage {
        contentMode = mode
        var oldImage = UIImage()
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() {
                oldImage = self.image!
                self.image = image
            }
            }.resume()
        self.image = oldImage
        return self.image!
    }
    func dowloadFromServer(link: String, contentMode mode: UIView.ContentMode = .center) -> UIImage {
        guard let url = URL(string: link) else { return UIImage() }
        return dowloadFromServer(url: url, contentMode: mode)
    }
}

@IBDesignable
class ArticleView: UIView {
}

extension UIView {
    
    @IBInspectable
    var cornerRadius1: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable
    var borderWidth1: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var borderColor1: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.borderColor = color.cgColor
            } else {
                layer.borderColor = nil
            }
        }
    }
    
    @IBInspectable
    var shadowRadius1: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }
    
    @IBInspectable
    var shadowOpacity1: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }
    
    @IBInspectable
    var shadowOffset1: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable
    var shadowColor1: UIColor? {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.shadowColor = color.cgColor
            } else {
                layer.shadowColor = nil
            }
        }
    }
}

extension String {
    func countInstances(of stringToFind: String) -> Int {
        var stringToSearch = self
        var count = 0
        while let foundRange = stringToSearch.range(of: stringToFind, options: .diacriticInsensitive) {
            stringToSearch = stringToSearch.replacingCharacters(in: foundRange, with: "")
            count += 1
        }
        return count
    }
}

