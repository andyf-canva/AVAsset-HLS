//
//  ViewController.swift
//  AVAsset+HLS
//
//  Created by Andy French on 21/2/2025.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let loader = Loader()
        Task {
            try await loader.main()
        }

    }


}

