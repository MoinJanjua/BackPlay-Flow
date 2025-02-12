//
//  WelcoemViewController.swift
//  BackPlay Flow
//
//  Created by Unique Consulting Firm on 24/01/2025.
//

import UIKit

class WelcoemViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func startbtn(_ sender:UIButton){
       
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "VideosListViewController") as! VideosListViewController
        newViewController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        newViewController.modalTransitionStyle = .crossDissolve
        self.present(newViewController, animated: true, completion: nil)
        
        
    }

}
