//
//  ScreenRedrawTimerSource.swift
//  PerformanceTools
//
//  Created by Timur Kuchkarov on 07.09.2020.
//  Copyright © 2020 Timur Kuchkarov. All rights reserved.
//

import Foundation
import QuartzCore

final class ScreenRedrawTimerProvider {
	private var displayLink: CADisplayLink?
	var currentState: ProviderState = .notRunning
	private var manualActions: ManualActions = []
	var callback: Callback?
}

extension ScreenRedrawTimerProvider: TimerProvider {
	func setTickCallback(_ callback: @escaping Callback) {
		self.callback = callback
	}

	var timestamp: TimeInterval {
		return displayLink?.timestamp ?? 0
	}

	func start(manually: Bool) {
		guard changeState(to: .initializing, with: {
			self.configureDisplayLink()
		}) else {
			return
		}
		guard changeState(to: .running, with: {
			self.displayLink?.isPaused = false
		}) else {
			return
		}
	}

	func stop(manually: Bool) {

		if manually {
			manualActions.insert(.stop)
		}
		guard changeState(to: .stopped, with: {
			self.destroyDisplayLink()
		}) else {
			return
		}
	}

	func pause(manually: Bool) {
		if manually {
			manualActions.insert(.pause)
		}
		guard changeState(to: .paused) else {
			return
		}
		displayLink?.isPaused = true
	}

	func resume(manually: Bool) {
		guard changeState(to: .running, with: {
			self.displayLink?.isPaused = false
		}) else {
			return
		}
	}
}

private extension ScreenRedrawTimerProvider {

	func configureDisplayLink() {
		guard displayLink == nil else {
			assertionFailure("Display link already exists, this might indicate a bug or access from multiple threads")
			return
		}
		displayLink = CADisplayLink(target: self, selector: #selector(displayLinkCallback(displayLink:)))
		displayLink?.isPaused = true
		displayLink?.add(to: .current, forMode: .common)
	}

	func destroyDisplayLink() {
		guard displayLink != nil else {
			assertionFailure("No display link to invalidate, this might indicate a bug or access from multiple threads")
			return
		}
		displayLink?.isPaused = true
		displayLink?.invalidate()
		displayLink = nil
	}

	@objc func displayLinkCallback(displayLink: CADisplayLink) {
		callback?(displayLink.timestamp)
	}
}

//case notRunning
//case initializing
//case running
//case paused
//case stopped
private extension ScreenRedrawTimerProvider {

	func changeState(to state: ProviderState, with closure: (() -> ())? = nil) -> Bool {
		switch (currentState, state) {
		case (.notRunning, .initializing),
			 (.initializing, .running),
			 (.running, .paused),
			 (.running, .stopped),
			 (.paused, .stopped):
			currentState = state
			closure?()
			return true
			// cases with prechecks
			// TODO: add prechecks(manual vs auto/system events like backgrounding)
		case (.paused, .running),
			 (.stopped, .running):
			currentState = state
			closure?()
			return true
		default:
			assertionFailure("unsupported transition from \(currentState) to \(state)")
			return false
		}
	}
}
