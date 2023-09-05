//
//  Array+Extensions.swift
//  CombineCoreBluetooth
//
//  Created by Nick Brook on 05/09/2023.
//

import Foundation

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
