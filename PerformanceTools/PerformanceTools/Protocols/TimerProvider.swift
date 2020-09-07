//
//  TimerProvider.swift
//  PerformanceTools
//
//  Created by Timur Kuchkarov on 06.09.2020.
//  Copyright © 2020 Timur Kuchkarov. All rights reserved.
//

import Foundation

protocol TimerProvider: ProviderLifetimeController {

	typealias Callback = (TimeInterval) -> Void

	func setTickCallback(_ callback: @escaping Callback)
	var timestamp: TimeInterval { get }
}
