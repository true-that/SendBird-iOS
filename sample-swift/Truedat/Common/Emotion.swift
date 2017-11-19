//
//  Emotion.swift
//  Truedat
//
//  Created by Ohad Navon on 19/11/2017.
//  Copyright © 2017 SendBird. All rights reserved.
//

import Foundation

/// Emotions to describe emotional reaction to scenes.
enum Emotion: String, Hashable {
  case happy, omg, disgust

  public var description: String { return self.rawValue }

  var hashValue: Int {
    return self.rawValue.hashValue
  }
}

// MARK: Emojis
extension Emotion {
  public var emoji: String {
    switch self {
    case .happy:
      return "😂"
    case .disgust:
      return "😩"
    case .omg:
      return "😱"
    }
  }
}
