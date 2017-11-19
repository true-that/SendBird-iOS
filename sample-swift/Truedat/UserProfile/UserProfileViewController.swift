//
//  UserProfileViewController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 6/21/17.
//  Copyright © 2017 SendBird. All rights reserved.
//
import UIKit
import SendBirdSDK
import RSKImageCropper
import Alamofire
import AlamofireImage
import Photos
import MobileCoreServices
class UserProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, RSKImageCropViewControllerDelegate {
  @IBOutlet weak var navItem: UINavigationItem!
  @IBOutlet weak var profileImageView: UIImageView!
  @IBOutlet weak var nicknameTextField: UITextField!
  @IBOutlet weak var bottomMargin: NSLayoutConstraint!
  @IBOutlet weak var pushNotificationSwitch: UISwitch!
  @IBOutlet weak var updatingIndicator: UIActivityIndicatorView!
  var profileImageData: Data?
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    let negativeRightSpacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
    negativeRightSpacer.width = -2
    let rightDisconnectItem = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.plain, target: self, action: #selector(save))
    rightDisconnectItem.setTitleTextAttributes([NSFontAttributeName: Constants.navigationBarButtonItemFont()], for: UIControlState.normal)
    let negativeLeftSpacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
    negativeLeftSpacer.width = -2
    let leftProfileItem = UIBarButtonItem(title: "Close", style: UIBarButtonItemStyle.plain, target: self, action: #selector(save))
    leftProfileItem.setTitleTextAttributes([NSFontAttributeName: Constants.navigationBarButtonItemFont()], for: UIControlState.normal)
    self.navItem.rightBarButtonItems = [negativeRightSpacer, rightDisconnectItem]
    self.navItem.leftBarButtonItems = [negativeLeftSpacer, leftProfileItem]
    self.profileImageView.af_setImage(withURL: URL(string: (SBDMain.getCurrentUser()?.profileUrl!)!)!)
    self.profileImageData = nil
    self.updatingIndicator.isHidden = true
    let profileImageTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(clickProfileImage))
    self.profileImageView.isUserInteractionEnabled = true
    self.profileImageView.addGestureRecognizer(profileImageTapRecognizer)
    self.nicknameTextField.text = SBDMain.getCurrentUser()?.nickname
    let isRegisteredForRemoteNotifications = UIApplication.shared.isRegisteredForRemoteNotifications
    self.pushNotificationSwitch.isOn = isRegisteredForRemoteNotifications
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  func close() {
    self.dismiss(animated: false, completion: nil)
  }

  func save() {
    if self.nicknameTextField.text?.trimmingCharacters(in: CharacterSet.whitespaces).characters.count == 0 {
      return
    }
    self.updatingIndicator.isHidden = false
    self.updatingIndicator.startAnimating()
    let isRegisteredForRemoteNotifications = self.pushNotificationSwitch.isOn
    if isRegisteredForRemoteNotifications {
      UIApplication.shared.registerForRemoteNotifications()
      SBDMain.updateCurrentUserInfo(withNickname: self.nicknameTextField.text?.trimmingCharacters(in: CharacterSet.whitespaces), profileImage: self.profileImageData, completionHandler: { error in
        var hasUpdatedUserInfo: Bool?
        if error != nil {
          hasUpdatedUserInfo = false
        } else {
          let imageDownloader = UIImageView.af_sharedImageDownloader
          let urlCache = imageDownloader.sessionManager.session.configuration.urlCache
          urlCache?.removeAllCachedResponses()
          _ = imageDownloader.imageCache?.removeImage(withIdentifier: (SBDMain.getCurrentUser()?.profileUrl)!)
          hasUpdatedUserInfo = true
        }
        #if !(arch(i386) || arch(x86_64))
          SBDMain.registerDevicePushToken(SBDMain.getPendingPushToken()!, unique: true, completionHandler: { status, error in
            var hasUpdatedPushNoti: Bool?
            if error != nil {
              hasUpdatedPushNoti = false
            } else {
              hasUpdatedPushNoti = true
            }
            if hasUpdatedUserInfo == false || hasUpdatedPushNoti == false {
              let vc = UIAlertController(title: Bundle.truedatLocalizedStringForKey(key: "ErrorTitle"), message: error?.domain, preferredStyle: UIAlertControllerStyle.alert)
              let closeAction = UIAlertAction(title: Bundle.truedatLocalizedStringForKey(key: "CloseButton"), style: UIAlertActionStyle.cancel, handler: nil)
              vc.addAction(closeAction)
              DispatchQueue.main.async {
                self.present(vc, animated: true, completion: nil)
              }
              self.updatingIndicator.isHidden = true
              self.updatingIndicator.stopAnimating()
              DispatchQueue.main.async {
                self.present(vc, animated: true, completion: nil)
              }
            } else {
              self.dismiss(animated: true, completion: nil)
            }
          })
        #else
          if hasUpdatedUserInfo == false {
            let vc = UIAlertController(title: Bundle.truedatLocalizedStringForKey(key: "ErrorTitle"), message: error?.domain, preferredStyle: UIAlertControllerStyle.alert)
            let closeAction = UIAlertAction(title: Bundle.truedatLocalizedStringForKey(key: "CloseButton"), style: UIAlertActionStyle.cancel, handler: nil)
            vc.addAction(closeAction)
            DispatchQueue.main.async {
              self.present(vc, animated: true, completion: nil)
            }
            self.updatingIndicator.isHidden = true
            self.updatingIndicator.stopAnimating()
            DispatchQueue.main.async {
              self.present(vc, animated: true, completion: nil)
            }
          } else {
            self.dismiss(animated: true, completion: nil)
          }
        #endif
      })
    } else {
      UIApplication.shared.unregisterForRemoteNotifications()
      SBDMain.updateCurrentUserInfo(withNickname: self.nicknameTextField.text?.trimmingCharacters(in: CharacterSet.whitespaces), profileImage: self.profileImageData, completionHandler: { error in
        var hasUpdatedUserInfo: Bool?
        if error != nil {
          hasUpdatedUserInfo = false
        } else {
          let imageDownloader = UIImageView.af_sharedImageDownloader
          let urlCache = imageDownloader.sessionManager.session.configuration.urlCache
          urlCache?.removeAllCachedResponses()
          _ = imageDownloader.imageCache?.removeImage(withIdentifier: (SBDMain.getCurrentUser()?.profileUrl)!)
          hasUpdatedUserInfo = true
        }
        #if !(arch(i386) || arch(x86_64))
          SBDMain.unregisterPushToken(SBDMain.getPendingPushToken()!, completionHandler: { response, error in
            var hasUpdatedPushNoti: Bool?
            if error != nil {
              hasUpdatedPushNoti = false
            } else {
              hasUpdatedPushNoti = true
            }
            if hasUpdatedUserInfo == false || hasUpdatedPushNoti == false {
              let vc = UIAlertController(title: Bundle.truedatLocalizedStringForKey(key: "ErrorTitle"), message: error?.domain, preferredStyle: UIAlertControllerStyle.alert)
              let closeAction = UIAlertAction(title: Bundle.truedatLocalizedStringForKey(key: "CloseButton"), style: UIAlertActionStyle.cancel, handler: nil)
              vc.addAction(closeAction)
              DispatchQueue.main.async {
                self.present(vc, animated: true, completion: nil)
              }
              self.updatingIndicator.isHidden = true
              self.updatingIndicator.stopAnimating()
              DispatchQueue.main.async {
                self.present(vc, animated: true, completion: nil)
              }
            } else {
              self.dismiss(animated: true, completion: nil)
            }
          })
        #else
          if hasUpdatedUserInfo == false {
            let vc = UIAlertController(title: Bundle.truedatLocalizedStringForKey(key: "ErrorTitle"), message: error?.domain, preferredStyle: UIAlertControllerStyle.alert)
            let closeAction = UIAlertAction(title: Bundle.truedatLocalizedStringForKey(key: "CloseButton"), style: UIAlertActionStyle.cancel, handler: nil)
            vc.addAction(closeAction)
            DispatchQueue.main.async {
              self.present(vc, animated: true, completion: nil)
            }
            self.updatingIndicator.isHidden = true
            self.updatingIndicator.stopAnimating()
            DispatchQueue.main.async {
              self.present(vc, animated: true, completion: nil)
            }
          } else {
            self.dismiss(animated: true, completion: nil)
          }
        #endif
      })
    }
  }

  func clickProfileImage() {
    let mediaUI = UIImagePickerController()
    mediaUI.sourceType = UIImagePickerControllerSourceType.photoLibrary
    let mediaTypes = [String(kUTTypeImage)]
    mediaUI.mediaTypes = mediaTypes
    mediaUI.delegate = self
    self.present(mediaUI, animated: true, completion: nil)
  }

  // MARK: UIImagePickerControllerDelegate
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
    let mediaType = info[UIImagePickerControllerMediaType] as! String
    picker.dismiss(animated: true) {
      if CFStringCompare(mediaType as CFString, kUTTypeImage, []) == CFComparisonResult.compareEqualTo {
        self.cropImage(imageData: UIImageJPEGRepresentation(info[UIImagePickerControllerOriginalImage] as! UIImage, 0.8)!)
      }
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
  }

  func cropImage(imageData: Data) {
    let image = UIImage(data: imageData)
    let imageCropVC: RSKImageCropViewController = RSKImageCropViewController(image: image!)
    imageCropVC.delegate = self
    imageCropVC.cropMode = RSKImageCropMode.square
    self.present(imageCropVC, animated: false, completion: nil)
  }

  // MARK: RSKImageCropViewControllerDelegate
  // Crop image has been canceled.
  func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
    controller.dismiss(animated: false, completion: nil)
  }

  // The original image has been cropped.
  func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect) {
    self.profileImageView.image = croppedImage
  }

  // The original image has been cropped. Additionally provides a rotation angle used to produce image.
  func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
    self.profileImageView.image = croppedImage
    var imageData = UIImageJPEGRepresentation(croppedImage, 0.7)
    var resizedImage = croppedImage
    let maxSize = 2 * 1024 * 1024 // 2MB
    if imageData!.count > maxSize {
      let reductionRatio = CGFloat(imageData!.count) / CGFloat(maxSize)
      let newSize = CGSize(width: resizedImage.size.width / reductionRatio, height: resizedImage.size.height / reductionRatio)
      UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0 / reductionRatio)
      resizedImage.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: newSize.width, height: newSize.height)))
      resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()
      imageData = UIImageJPEGRepresentation(resizedImage, 0.7)
    }
    self.profileImageData = imageData
    controller.dismiss(animated: false, completion: nil)
  }

  // The original image will be cropped.
  func imageCropViewController(_ controller: RSKImageCropViewController, willCropImage originalImage: UIImage) {
    // Use when `applyMaskToCroppedImage` set to YES.
  }
}
