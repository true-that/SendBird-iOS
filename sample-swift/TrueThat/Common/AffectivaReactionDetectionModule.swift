//
//  AffectivaReactionDetectionModule.swift
//  Truedat
//
//  Created by Ohad Navon on 19/11/2017.
//  Copyright © 2017 SendBird. All rights reserved.
//

import Affdex
import UIKit

class AffectivaReactionDetectionModule {
  fileprivate static let detectionThreshold = 20 as CGFloat
  private var detector: AFDXDetector?
  var emotionToLikelihood: [AffectivaEmotion: CGFloat] = [
    AffectivaEmotion.joy: 0,
    AffectivaEmotion.surprise: 0,
    AffectivaEmotion.anger: 0,
    AffectivaEmotion.sadness: 0,
    AffectivaEmotion.fear: 0,
    AffectivaEmotion.disgust: 0,
    ]
  var delegate: ReactionDetectionDelegate? {
    didSet{
      emotionToLikelihood = [
        AffectivaEmotion.joy: 0,
        AffectivaEmotion.surprise: 0,
        AffectivaEmotion.anger: 0,
        AffectivaEmotion.sadness: 0,
        AffectivaEmotion.fear: 0,
        AffectivaEmotion.disgust: 0,
      ]
    }
  }

  init() {
    detector = AFDXDetector(delegate: self, using: frontCamera, maximumFaces: 1, face: LARGE_FACES)
    detector?.setDetectAllEmotions(true)
  }

  func start() {
    detector?.start()
  }

  func stop() {
    detector?.stop()
  }

    /// Get Devices
  var frontCamera: AVCaptureDevice? {
    if let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice] {
      return devices.filter({ $0.position == AVCaptureDevicePosition.front }).first
    }
    return nil
  }
}

extension AffectivaReactionDetectionModule: AFDXDetectorDelegate {
  func detectorDidStartDetectingFace(face: AFDXFace) {
  }

  func detectorDidStopDetectingFace(face: AFDXFace) {
  }

  func detector(_ detector: AFDXDetector, hasResults: NSMutableDictionary?, for forImage: UIImage,
                atTime: TimeInterval) {
    if hasResults != nil {
      for (_, face) in hasResults! {
        let affdexFace = face as! AFDXFace
        // Convert detected image to our enum
        emotionToLikelihood[.joy] = emotionToLikelihood[.joy]! + affdexFace.emotions.joy
        emotionToLikelihood[.sadness] = emotionToLikelihood[.sadness]! +  affdexFace.emotions.sadness
        emotionToLikelihood[.anger] = emotionToLikelihood[.anger]! +  affdexFace.emotions.anger
        emotionToLikelihood[.surprise] = emotionToLikelihood[.surprise]! +  affdexFace.emotions.surprise
        // Fear is harder to detect, and so it is amplified
        emotionToLikelihood[.fear] = emotionToLikelihood[.fear]! +  affdexFace.emotions.fear * 3
        // Disgust is too easy to detect, and so it is decreased
        emotionToLikelihood[.disgust] = emotionToLikelihood[.disgust]! +  affdexFace.emotions.disgust / 2
        let significantEnough = emotionToLikelihood.filter { $1 > AffectivaReactionDetectionModule.detectionThreshold }
        if significantEnough.isEmpty {
          return
        }
        let mostLikely = significantEnough.max(by: { $0.value > $1.value })
        if mostLikely != nil {
          delegate?.didDetect(reaction: mostLikely!.key.toEmotion()!, mostLikely: true)
        }
        for emotionLikelihoodEntry in significantEnough {
          if emotionLikelihoodEntry.key != mostLikely!.key {
            delegate?.didDetect(reaction: emotionLikelihoodEntry.key.toEmotion()!, mostLikely: false)
          }
        }
      }
    }
  }
}

enum AffectivaEmotion: Int, Hashable {
  case joy, surprise, anger, sadness, fear, disgust

  var hashValue: Int {
    return self.rawValue.hashValue
  }

  func toEmotion() -> Emotion? {
    switch self {
    case .joy:
      return .happy
    case .surprise:
      return .omg
    case .fear:
      return .omg
    case .anger:
      return .disgust
    case .disgust:
      return .disgust
    case .sadness:
      return .disgust
    default:
      return nil
    }
  }
}

protocol ReactionDetectionDelegate {

  /// Callback for detected reactions handling.
  ///
  /// - Parameter reaction: that was detected.
  /// - Parameter mostLikely: whether `reaction` is the most likely reaction or just significant enough (i.e. in cases
  ///                         where multiple reactions apply, say the user is suprised and smiles, one of the detected
  ///                         emotions will have `mostLikely = false`.
  func didDetect(reaction: Emotion, mostLikely: Bool)
}

