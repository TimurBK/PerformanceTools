//
//  SystemCountersHelper.swift
//  PerformanceTools
//
//  Created by Timur Kuchkarov on 12.07.2020.
//  Copyright © 2020 Timur Kuchkarov. All rights reserved.
//

import Foundation

public final class SystemCountersHelperImpl: SystemCountersHelper {
	public init() {}

//	public var TASK_POWER_INFO_V2: Int32 { get }
//
//	public struct gpu_energy_data {
//
//		public var task_gpu_utilisation: UInt64
//
//		public var task_gpu_stat_reserved0: UInt64
//
//		public var task_gpu_stat_reserved1: UInt64
//
//		public var task_gpu_stat_reserved2: UInt64
//
//		public init()
//
//		public init(task_gpu_utilisation: UInt64, task_gpu_stat_reserved0: UInt64, task_gpu_stat_reserved1: UInt64, task_gpu_stat_reserved2: UInt64)
//	}
//
//	public typealias gpu_energy_data_t = UnsafeMutablePointer<gpu_energy_data>
//	public struct task_power_info_v2 {
//
//		public var cpu_energy: task_power_info_data_t
//
//		public var gpu_energy: gpu_energy_data
//
//		public var task_ptime: UInt64
//
//		public var task_pset_switches: UInt64
//
//		public init()
//
//		public init(cpu_energy: task_power_info_data_t, gpu_energy: gpu_energy_data, task_ptime: UInt64, task_pset_switches: UInt64)
//	}
	
	public func memoryFootprint() -> mach_vm_size_t? {
		let TASK_VM_INFO_COUNT = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
		let TASK_VM_INFO_REV1_COUNT = mach_msg_type_number_t(MemoryLayout.offset(of: \task_vm_info_data_t.min_address)! / MemoryLayout<integer_t>.size)
		var info = task_vm_info_data_t()
		var count = TASK_VM_INFO_COUNT
		let kr = withUnsafeMutablePointer(to: &info) { infoPtr in
			infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
				task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &count)
			}
		}
		guard kr == KERN_SUCCESS, count >= TASK_VM_INFO_REV1_COUNT else {
			return nil
		}
		return info.phys_footprint
	}

	public func cpuUsage() -> Double? {
		var task_info_count: mach_msg_type_number_t

		task_info_count = mach_msg_type_number_t(TASK_INFO_MAX)
		var tinfo = [integer_t](repeating: 0, count: Int(task_info_count))

		guard task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), &tinfo, &task_info_count) == KERN_SUCCESS else {
			return nil
		}

		var thread_list: thread_act_array_t?
        var thread_count: mach_msg_type_number_t = 0

        guard task_threads(mach_task_self_, &thread_list, &thread_count) == KERN_SUCCESS else {
			return nil
		}
        guard let threads = thread_list else {
			return nil
		}

        defer {
            let size = MemoryLayout<thread_t>.stride * Int(thread_count)
			vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(size))
		}

		var tot_cpu: Double = 0

		for j in 0 ..< Int(thread_count) {
			var thread_info_count = mach_msg_type_number_t(THREAD_INFO_MAX)
			var thinfo = [integer_t](repeating: 0, count: Int(thread_info_count))
			guard thread_info(threads[j],
							  thread_flavor_t(THREAD_BASIC_INFO),
							  &thinfo,
							  &thread_info_count) == KERN_SUCCESS else {
				return nil
			}

			let threadBasicInfo = convertThreadInfoToThreadBasicInfo(thinfo)

			if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
				tot_cpu += (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE)) * 100.0
			}
		} // for each thread

		return tot_cpu
	}

	fileprivate func convertThreadInfoToThreadBasicInfo(_ threadInfo: [integer_t]) -> thread_basic_info {
		var result = thread_basic_info()

		result.user_time = time_value_t(seconds: threadInfo[0], microseconds: threadInfo[1])
		result.system_time = time_value_t(seconds: threadInfo[2], microseconds: threadInfo[3])
		result.cpu_usage = threadInfo[4]
		result.policy = threadInfo[5]
		result.run_state = threadInfo[6]
		result.flags = threadInfo[7]
		result.suspend_count = threadInfo[8]
		result.sleep_time = threadInfo[9]

		return result
	}
}

public protocol SystemCountersHelper {
	func memoryFootprint() -> mach_vm_size_t?
	func cpuUsage() -> Double?
}
