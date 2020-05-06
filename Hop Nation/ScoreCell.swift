//
//  ScoreCell.swift
//  Hop Nation
//
//  Created by Ben Goldstein on 1/28/19.
//  Copyright © 2019 Benjamin Goldstein. All rights reserved.
//

import UIKit
import Alamofire

class ScoreCell: UITableViewCell {
    
    @IBOutlet weak var topicPic: UIImageView!
    @IBOutlet weak var hopImage: UIImageView!
    @IBOutlet weak var hopLabel: UILabel!
    @IBOutlet weak var topicLabel: UILabel!
    @IBOutlet weak var opponentLabel: UILabel!
    @IBOutlet weak var opponentScore: UILabel!
    @IBOutlet weak var hopScore: UILabel!
    @IBOutlet weak var opponentImage: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var sharebtn: UIButton!
    
    var delegate: ScoreCellDelegate!
    var myimage = UIImage()
    var myDataDict = [String: String]()
    let topics = ["Cross Country", "Field Hockey", "Football", "Soccer", "Volleyball", "Water Polo", "Basketball", "Fencing", "Track", "Ski Team", "Squash", "Swim", "Wrestling", "Baseball", "Crew", "Golf", "Lacrosse", "Softball", "Tennis"]
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let barbtn = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: nil)
        sharebtn.setImage(barbtn.image, for: .normal)
//        sharebtn.setTitle("", for: .normal)
        sharebtn.addTarget(self, action: #selector(shareScore), for: .touchUpInside)
        // Initialization code
    }
    
    @objc func shareScore() {
        delegate.shareArticle(cell: self)
    }
    
    func fill() {
        hopImage.image = UIImage(named: "Hop")
        topicLabel.text = myDataDict["topic"]
        for topic in topics {
            if topicLabel.text?.lowercased().range(of: topic.lowercased()) != nil {
                topicPic.image = UIImage(named: topic)
            }
        }
        hopLabel.text = "Hopkins"
        opponentLabel.text = myDataDict["opponent"]
        if opponentLabel.text?.count ?? 0 > 0 {
            opponentImage.text = String(myDataDict["opponent"]!.first!).uppercased()
        } else {
            opponentImage.text = "X"
        }
        dateLabel.text = myDataDict["date"]
        var hopscore = ""
        var oppscore = ""
        var hyphenfound = false
        if let datascore = myDataDict["score"] {
            for char in datascore {
                if char == "-" {
                    hyphenfound = true
                }
                else if hyphenfound {
                    oppscore = oppscore + String(char)
                } else {
                    hopscore = hopscore + String(char)
                }
            }
        }
        hopScore.textColor = UIColor(displayP3Red: 100/255, green: 0, blue: 0, alpha: 1)
        opponentScore.textColor = UIColor.darkGray
        hopScore.text = hopscore
        opponentScore.text = oppscore
        if myDataDict["canceled"]! != "pizza" {
            hopScore.text = "X"
            opponentScore.text = "X"
            hopScore.textColor = .red
            opponentScore.textColor = .red
        }
        UIGraphicsBeginImageContextWithOptions(self.contentView.bounds.size, self.contentView.isOpaque, 0.0)
        defer { UIGraphicsEndImageContext() }
        if let context = UIGraphicsGetCurrentContext() {
            self.contentView.layer.render(in: context)
            let imagery = UIGraphicsGetImageFromCurrentImageContext()
            self.myimage = imagery!
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
