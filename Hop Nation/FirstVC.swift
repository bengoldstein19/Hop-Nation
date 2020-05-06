//
//  FirstVC.swift
//  Hop Nation
//
//  Created by Ben Goldstein on 1/30/19.
//  Copyright © 2019 Benjamin Goldstein. All rights reserved.
//

import UIKit

class FirstVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        testConnection()
        // Do any additional setup after loading the view.
    }
    
    @objc func segue() {
        self.performSegue(withIdentifier: "toApp", sender: nil)
    }
    
    func testConnection() {
        let gestrec = UITapGestureRecognizer(target: self, action: #selector(segue))
        self.view.addGestureRecognizer(gestrec)
        let imgview = UIImageView(image: UIImage(named: "Hop"))
        imgview.frame = .zero
        imgview.contentMode = .scaleAspectFit
        self.view.addSubview(imgview)
        let label = UILabel(frame: .zero)
        label.text = "Tap Anywhere to Enter"
        label.textColor = UIColor(displayP3Red: 100/255, green: 0, blue: 0, alpha: 1)
        label.font = label.font.withSize(30)
        label.textAlignment = .center
        self.view.addSubview(label)
        UIView.animate(withDuration: 2, animations: {
            imgview.frame = self.view.frame
            label.frame = CGRect(x: 20, y: self.view.frame.height/6, width: self.view.frame.width - 40, height: 50)
        })
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
