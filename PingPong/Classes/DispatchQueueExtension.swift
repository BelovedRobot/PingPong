//
//  DispatchQueueExtension.swift
//  PingPong
//
//  Created by Juan Manuel Pereira on 8/13/17.
//  Copyright © 2017 Beloved Robot. All rights reserved.
//

import Foundation

extension DispatchQueue {
    static var userInteractive: DispatchQueue { return DispatchQueue.global(qos: .userInteractive) }
    static var userInitiated: DispatchQueue { return DispatchQueue.global(qos: .userInitiated) }
    static var utility: DispatchQueue { return DispatchQueue.global(qos: .utility) }
    public static var backgroundQueue: DispatchQueue { return DispatchQueue.global(qos: .background) }
}
