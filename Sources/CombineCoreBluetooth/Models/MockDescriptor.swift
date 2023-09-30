//
//  File.swift
//  
//
//  Created by Nick Brook on 30/09/2023.
//

import Foundation
import CoreBluetooth

class MockDescriptor: CBMutableDescriptor {

    open var _value: Any?
    /**
     *  @property value
     *
     *  @discussion
     *      The value of the descriptor. The corresponding value types for the various descriptors are detailed in @link CBUUID.h @/link.
     *
     */
    override open var value: Any? {
        get { _value }
        set { _value = newValue }
    }
}
