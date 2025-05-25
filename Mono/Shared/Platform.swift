//
//  Platform.swift
//  Mono
//
//  Cross‑platform aliases for UIKit/AppKit types.
//
//  Created by Eduardo Freire on 05/05/25.
//

#if os(macOS)
import AppKit
public typealias UXFont  = NSFont
public typealias UXImage = NSImage
public typealias UXView  = NSView
#else
import UIKit
public typealias UXColor = UIColor
public typealias UXFont  = UIFont
public typealias UXImage = UIImage
public typealias UXView  = UIView
#endif
