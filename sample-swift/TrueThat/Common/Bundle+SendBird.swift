//
//  Bundle+SendBird.swift
//  SendBird-iOS
//
//  Created by Jed Kyung on 10/18/16.
//  Copyright © 2016 SendBird. All rights reserved.
//

import Foundation

extension Bundle {
  static func truedatBundle() -> Bundle {
    return Bundle(for: ViewController.self)
  }

  static func truedatResourceBundle() -> Bundle {
    let bundleResourcePath = Bundle.truedatBundle().resourcePath
    let assetPath = bundleResourcePath?.appending("/Truedat.bundle")
    return Bundle(path: assetPath!)!
  }

  static func truedatLocalizedStringForKey(key: String) -> String {
    return NSLocalizedString(key, tableName: "Localizable", bundle: Bundle.truedatResourceBundle(), comment: "")
  }
}
