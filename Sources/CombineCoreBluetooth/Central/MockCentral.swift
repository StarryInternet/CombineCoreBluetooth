//
//  File.swift
//  
//
//  Created by Nick Brook on 27/09/2023.
//

import Foundation

public class MockCentral {
    
    private(set) public var central: Central!
    
    public var maximumUpdateValueLength: Int = 512
    
    public init(identifier: UUID = UUID()) {
        central = Central.unimplemented(identifier: identifier, maximumUpdateValueLength: { self.maximumUpdateValueLength })
    }
    
}
