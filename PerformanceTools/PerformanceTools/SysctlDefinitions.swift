//
//  SysctlDefinitions.swift
//  PerformanceTools
//
//  Created by Timur Kuchkarov on 12.07.2020.
//  Copyright © 2020 Timur Kuchkarov. All rights reserved.
//

import Foundation

enum HW {

}


public protocol SysctlNameRepresentable: RawRepresentable where RawValue == String {}


public extension SysctlNameRepresentable {

	init?(rawValue: String) {
		return nil
	}

	var rawValue: String {
		let full = String(reflecting: type(of: self)) + ".\(self)"
		return full.replacingOccurrences(of: "\"", with: "").split(separator: ".").dropFirst().map(String.init).joined(separator: ".").lowercased()
	}
}
