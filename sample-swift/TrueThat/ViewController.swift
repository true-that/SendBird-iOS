//
//  ViewController.swift
//  SendBird-iOS
//
//  Created by Jed Kyung on 10/6/16.
//  Copyright © 2016 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK

class ViewController: UITableViewController, UITextFieldDelegate {
  fileprivate static let minUserIdLength = 6
  fileprivate static let minNicknameLength = 3
  @IBOutlet weak var connectButton: UIButton!
  @IBOutlet weak var nicknameLabel: UILabel!
  @IBOutlet weak var nicknameTextField: UITextField!
  @IBOutlet weak var nicknameLineView: UIView!
  @IBOutlet weak var indicatorView: UIActivityIndicatorView!
  @IBOutlet weak var versionLabel: UILabel!

  @IBOutlet weak var nicknameLabelBottomMargin: NSLayoutConstraint!

  override func viewDidLoad() {
    super.viewDidLoad()

    // Version
    let path = Bundle.main.path(forResource: "Info", ofType: "plist")
    if path != nil {
      let infoDict = NSDictionary(contentsOfFile: path!)
      let sampleUIVersion = infoDict?["CFBundleShortVersionString"] as! String
      let version = String(format: "v%@ / SDK v%@", sampleUIVersion, SBDMain.getSDKVersion())
      self.versionLabel.text = version
    }

    self.nicknameTextField.delegate = self

    self.nicknameLabel.alpha = 0

    let userId = UserDefaults.standard.object(forKey: "sendbird_user_id") as? String
    let userNickname = UserDefaults.standard.object(forKey: "sendbird_user_nickname") as? String

    self.nicknameLineView.backgroundColor = Constants.textFieldLineColorNormal()

    if userNickname != nil && (userNickname?.characters.count)! > 0 {
      self.nicknameLabelBottomMargin.constant = 0
      self.view.setNeedsUpdateConstraints()
      self.nicknameLabel.alpha = 1
      self.view.layoutIfNeeded()
    }

    self.nicknameTextField.text = userNickname

    self.connectButton.setBackgroundImage(Utils.imageFromColor(color: Constants.connectButtonColor()), for: UIControlState.normal)

    self.indicatorView.hidesWhenStopped = true

    self.nicknameTextField.addTarget(self, action: #selector(nicknameTextFieldDidChange(sender:)), for: UIControlEvents.editingChanged)

    if userId != nil && (userId?.characters.count)! > 0 && userNickname != nil && (userNickname?.characters.count)! > 0 {
      self.connect()
    }

  }

  @IBAction func clickConnectButton(_ sender: AnyObject) {
    if nicknameTextField.text == nil {
      return
    }
    if nicknameTextField.text!.count < ViewController.minNicknameLength {
      return
    }
    self.connect()
  }

  func connect() {
    let trimmedUserId: String = UIDevice.current.identifierForVendor!.uuidString
    let trimmedNickname: String = (self.nicknameTextField.text?.trimmingCharacters(in: NSCharacterSet.whitespaces))!
    if trimmedUserId.characters.count > 0 && trimmedNickname.characters.count > 0 {
      self.nicknameTextField.isEnabled = false

      self.indicatorView.startAnimating()

      SBDMain.connect(withUserId: trimmedUserId, completionHandler: { user, error in
        if error != nil {
          DispatchQueue.main.async {
            self.nicknameTextField.isEnabled = true

            self.indicatorView.stopAnimating()
          }

          let vc = UIAlertController(title: Bundle.truedatLocalizedStringForKey(key: "ErrorTitle"), message: error?.domain, preferredStyle: UIAlertControllerStyle.alert)
          let closeAction = UIAlertAction(title: Bundle.truedatLocalizedStringForKey(key: "CloseButton"), style: UIAlertActionStyle.cancel, handler: nil)
          vc.addAction(closeAction)
          DispatchQueue.main.async {
            self.present(vc, animated: true, completion: nil)
          }

          return
        }

        if SBDMain.getPendingPushToken() != nil {
          SBDMain.registerDevicePushToken(SBDMain.getPendingPushToken()!, unique: true, completionHandler: { status, error in
            if error == nil {
              if status == SBDPushTokenRegistrationStatus.pending {
                print("Push registeration is pending.")
              } else {
                print("APNS Token is registered.")
              }
            } else {
              print("APNS registration failed.")
            }
          })
        }

        SBDMain.updateCurrentUserInfo(withNickname: trimmedNickname, profileUrl: nil, completionHandler: { error in
          DispatchQueue.main.async {
            self.nicknameTextField.isEnabled = true

            self.indicatorView.stopAnimating()
          }

          if error != nil {
            let vc = UIAlertController(title: Bundle.truedatLocalizedStringForKey(key: "ErrorTitle"), message: error?.domain, preferredStyle: UIAlertControllerStyle.alert)
            let closeAction = UIAlertAction(title: Bundle.truedatLocalizedStringForKey(key: "CloseButton"), style: UIAlertActionStyle.cancel, handler: nil)
            vc.addAction(closeAction)
            DispatchQueue.main.async {
              self.present(vc, animated: true, completion: nil)
            }

            SBDMain.disconnect(completionHandler: {

            })

            return
          }

          UserDefaults.standard.set(SBDMain.getCurrentUser()?.userId, forKey: "sendbird_user_id")
          UserDefaults.standard.set(SBDMain.getCurrentUser()?.nickname, forKey: "sendbird_user_nickname")
        })

        DispatchQueue.main.async {
//          let vc = MenuViewController(nibName: "MenuViewController", bundle: Bundle.main)
          let vc = GroupChannelListViewController(nibName: "GroupChannelListViewController", bundle: Bundle.main)
          vc.addDelegates()
          self.present(vc, animated: false, completion: nil)
        }
      })
    }
  }

  func nicknameTextFieldDidChange(sender: UITextField) {
    if sender.text?.characters.count == 0 {
      self.nicknameLabelBottomMargin.constant = -12
      self.view.setNeedsUpdateConstraints()
      UIView.animate(withDuration: 0.1, animations: {
        self.nicknameLabel.alpha = 0
        self.view.layoutIfNeeded()
      })
    } else {
      self.nicknameLabelBottomMargin.constant = 0
      self.view.setNeedsUpdateConstraints()
      UIView.animate(withDuration: 0.2, animations: {
        self.nicknameLabel.alpha = 1
        self.view.layoutIfNeeded()
      })
    }
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    self.view.endEditing(true)
  }

  // MARK: UITextFieldDelegate
  func textFieldDidBeginEditing(_ textField: UITextField) {
    if textField == self.nicknameTextField {
      self.nicknameLineView.backgroundColor = Constants.textFieldLineColorSelected()
    }
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    if textField == self.nicknameTextField {
      self.nicknameLineView.backgroundColor = Constants.textFieldLineColorNormal()
    }
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == self.nicknameTextField {
      if textField.text != nil && textField.text!.count > ViewController.minNicknameLength {
        connect()
        return true
      }
      return false
    }
    return true
  }
}
