//
//  ProviderLifetimeController.swift
//  PerformanceTools
//
//  Created by Timur Kuchkarov on 06.09.2020.
//  Copyright © 2020 Timur Kuchkarov. All rights reserved.
//

import Foundation

struct ManualActions: OptionSet {
    let rawValue: Int

    static let pause = ManualActions(rawValue: 1 << 0)
    static let stop = ManualActions(rawValue: 1 << 1)
    static let all: ManualActions = [.pause, .stop]
}

enum ProviderState {
	case notRunning
	case initializing
	case running
	case paused
	case stopped
}

protocol ProviderLifetimeController {
	func start(manually: Bool)
	func stop(manually: Bool)
	func pause(manually: Bool)
	func resume(manually: Bool)

	var currentState: ProviderState { get }
}
