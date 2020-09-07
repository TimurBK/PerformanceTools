//
//  ViewController.swift
//  PerformanceToolsSampleApp
//
//  Created by Timur Kuchkarov on 29.06.2020.
//  Copyright © 2020 Timur Kuchkarov. All rights reserved.
//

import UIKit

import PerformanceTools

class ViewController: UIViewController {

	var helper: SystemCountersHelper?
	var timer: Timer?

	override func viewDidLoad() {
		super.viewDidLoad()
		helper = SystemCountersHelperImpl()

		timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {[weak self] _ in
			print("====================")
			print("[!!!111]memory = \(String(describing: self?.helper?.memoryFootprint()))\n")
			print("cpu: \(String(describing: self?.helper?.cpuUsage()))")
		}
		// Do any additional setup after loading the view.
	}

	deinit {
		timer?.invalidate()
	}


}

