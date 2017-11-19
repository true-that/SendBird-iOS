//
//  ChattingView.swift
//  SendBird-iOS
//
//  Created by Jed Kyung on 10/7/16.
//  Copyright © 2016 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import Alamofire
import AlamofireImage
import FLAnimatedImage

protocol ChattingViewDelegate: class {
  func loadMoreMessage(view: UIView)
  func startTyping(view: UIView)
  func endTyping(view: UIView)
  func hideKeyboardWhenFastScrolling(view: UIView)
}

class ChattingView: ReusableViewFromXib, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {
  @IBOutlet weak var messageTextView: UITextView!
  @IBOutlet weak var chattingTableView: UITableView!
  @IBOutlet weak var inputContainerViewHeight: NSLayoutConstraint!
  var messages: [SBDBaseMessage] = []

  var resendableMessages: [String: SBDBaseMessage] = [:]
  var preSendMessages: [String: SBDBaseMessage] = [:]

  var resendableFileData: [String: [String: AnyObject]] = [:]
  var preSendFileData: [String: [String: AnyObject]] = [:]

  @IBOutlet weak var fileAttachButton: UIButton!
  @IBOutlet weak var sendButton: UIButton!
  var stopMeasuringVelocity: Bool = true
  var initialLoading: Bool = true

  var delegate: (ChattingViewDelegate & MessageDelegate)?

  @IBOutlet weak var typingIndicatorContainerViewHeight: NSLayoutConstraint!
  @IBOutlet weak var typingIndicatorImageView: UIImageView!
  @IBOutlet weak var typingIndicatorLabel: UILabel!
  @IBOutlet weak var typingIndicatorContainerView: UIView!
  @IBOutlet weak var typingIndicatorImageHeight: NSLayoutConstraint!

  var incomingUserMessageSizingTableViewCell: IncomingUserMessageTableViewCell?
  var outgoingUserMessageSizingTableViewCell: OutgoingUserMessageTableViewCell?
  var neutralMessageSizingTableViewCell: NeutralMessageTableViewCell?
  var incomingFileMessageSizingTableViewCell: IncomingFileMessageTableViewCell?
  var outgoingImageFileMessageSizingTableViewCell: OutgoingImageFileMessageTableViewCell?
  var outgoingFileMessageSizingTableViewCell: OutgoingFileMessageTableViewCell?
  var incomingImageFileMessageSizingTableViewCell: IncomingImageFileMessageTableViewCell?
  var incomingVideoFileMessageSizingTableViewCell: IncomingVideoFileMessageTableViewCell?
  var outgoingVideoFileMessageSizingTableViewCell: OutgoingVideoFileMessageTableViewCell?
  var incomingGeneralUrlPreviewMessageTableViewCell: IncomingGeneralUrlPreviewMessageTableViewCell?
  var outgoingGeneralUrlPreviewMessageTableViewCell: OutgoingGeneralUrlPreviewMessageTableViewCell?
  var outgoingGeneralUrlPreviewTempMessageTableViewCell: OutgoingGeneralUrlPreviewTempMessageTableViewCell?

  @IBOutlet weak var placeholderLabel: UILabel!

  var lastMessageHeight: CGFloat = 0
  var scrollLock: Bool = false

  var lastOffset: CGPoint = CGPoint(x: 0, y: 0)
  var lastOffsetCapture: TimeInterval = 0
  var isScrollingFast: Bool = false

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.setup()
  }

  func setup() {
    self.chattingTableView.contentInset = UIEdgeInsetsMake(0, 0, 10, 0)
    self.messageTextView.textContainerInset = UIEdgeInsetsMake(15.5, 0, 14, 0)
  }

  func initChattingView() {
    self.initialLoading = true
    self.lastMessageHeight = 0
    self.scrollLock = false
    self.stopMeasuringVelocity = false

    self.typingIndicatorContainerView.isHidden = true
    self.typingIndicatorContainerViewHeight.constant = 0
    self.typingIndicatorImageHeight.constant = 0

    //        self.typingIndicatorContainerView.layoutIfNeeded()

    self.messageTextView.delegate = self

    self.chattingTableView.register(IncomingUserMessageTableViewCell.nib(), forCellReuseIdentifier: IncomingUserMessageTableViewCell.cellReuseIdentifier())
    self.chattingTableView.register(OutgoingUserMessageTableViewCell.nib(), forCellReuseIdentifier: OutgoingUserMessageTableViewCell.cellReuseIdentifier())
    self.chattingTableView.register(NeutralMessageTableViewCell.nib(), forCellReuseIdentifier: NeutralMessageTableViewCell.cellReuseIdentifier())
    self.chattingTableView.register(IncomingFileMessageTableViewCell.nib(), forCellReuseIdentifier: IncomingFileMessageTableViewCell.cellReuseIdentifier())
    self.chattingTableView.register(OutgoingImageFileMessageTableViewCell.nib(), forCellReuseIdentifier: OutgoingImageFileMessageTableViewCell.cellReuseIdentifier())
    self.chattingTableView.register(OutgoingFileMessageTableViewCell.nib(), forCellReuseIdentifier: OutgoingFileMessageTableViewCell.cellReuseIdentifier())
    self.chattingTableView.register(IncomingImageFileMessageTableViewCell.nib(), forCellReuseIdentifier: IncomingImageFileMessageTableViewCell.cellReuseIdentifier())
    self.chattingTableView.register(IncomingVideoFileMessageTableViewCell.nib(), forCellReuseIdentifier: IncomingVideoFileMessageTableViewCell.cellReuseIdentifier())
    self.chattingTableView.register(OutgoingVideoFileMessageTableViewCell.nib(), forCellReuseIdentifier: OutgoingVideoFileMessageTableViewCell.cellReuseIdentifier())

    self.chattingTableView.register(IncomingGeneralUrlPreviewMessageTableViewCell.nib(), forCellReuseIdentifier: IncomingGeneralUrlPreviewMessageTableViewCell.cellReuseIdentifier())
    self.chattingTableView.register(OutgoingGeneralUrlPreviewMessageTableViewCell.nib(), forCellReuseIdentifier: OutgoingGeneralUrlPreviewMessageTableViewCell.cellReuseIdentifier())
    self.chattingTableView.register(OutgoingGeneralUrlPreviewTempMessageTableViewCell.nib(), forCellReuseIdentifier: OutgoingGeneralUrlPreviewTempMessageTableViewCell.cellReuseIdentifier())

    self.chattingTableView.delegate = self
    self.chattingTableView.dataSource = self

    self.initSizingCell()
  }

  func initSizingCell() {
    self.incomingUserMessageSizingTableViewCell = IncomingUserMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? IncomingUserMessageTableViewCell
    self.incomingUserMessageSizingTableViewCell?.frame = self.frame
    self.incomingUserMessageSizingTableViewCell?.isHidden = true
    self.addSubview(self.incomingUserMessageSizingTableViewCell!)

    self.outgoingUserMessageSizingTableViewCell = OutgoingUserMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? OutgoingUserMessageTableViewCell
    self.outgoingUserMessageSizingTableViewCell?.frame = self.frame
    self.outgoingUserMessageSizingTableViewCell?.isHidden = true
    self.addSubview(self.outgoingUserMessageSizingTableViewCell!)

    self.neutralMessageSizingTableViewCell = NeutralMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? NeutralMessageTableViewCell
    self.neutralMessageSizingTableViewCell?.frame = self.frame
    self.neutralMessageSizingTableViewCell?.isHidden = true
    self.addSubview(self.neutralMessageSizingTableViewCell!)

    self.incomingFileMessageSizingTableViewCell = IncomingFileMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? IncomingFileMessageTableViewCell
    self.incomingFileMessageSizingTableViewCell?.frame = self.frame
    self.incomingFileMessageSizingTableViewCell?.isHidden = true
    self.addSubview(self.incomingFileMessageSizingTableViewCell!)

    self.outgoingImageFileMessageSizingTableViewCell = OutgoingImageFileMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? OutgoingImageFileMessageTableViewCell
    self.outgoingImageFileMessageSizingTableViewCell?.frame = self.frame
    self.outgoingImageFileMessageSizingTableViewCell?.isHidden = true
    self.addSubview(self.outgoingImageFileMessageSizingTableViewCell!)

    self.outgoingFileMessageSizingTableViewCell = OutgoingFileMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? OutgoingFileMessageTableViewCell
    self.outgoingFileMessageSizingTableViewCell?.frame = self.frame
    self.outgoingFileMessageSizingTableViewCell?.isHidden = true
    self.addSubview(self.outgoingFileMessageSizingTableViewCell!)

    self.incomingImageFileMessageSizingTableViewCell = IncomingImageFileMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? IncomingImageFileMessageTableViewCell
    self.incomingImageFileMessageSizingTableViewCell?.frame = self.frame
    self.incomingImageFileMessageSizingTableViewCell?.isHidden = true
    self.addSubview(self.incomingImageFileMessageSizingTableViewCell!)

    self.incomingVideoFileMessageSizingTableViewCell = IncomingVideoFileMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? IncomingVideoFileMessageTableViewCell
    self.incomingVideoFileMessageSizingTableViewCell?.frame = self.frame
    self.incomingVideoFileMessageSizingTableViewCell?.isHidden = true
    self.addSubview(self.incomingVideoFileMessageSizingTableViewCell!)

    self.outgoingVideoFileMessageSizingTableViewCell = OutgoingVideoFileMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? OutgoingVideoFileMessageTableViewCell
    self.outgoingVideoFileMessageSizingTableViewCell?.frame = self.frame
    self.outgoingVideoFileMessageSizingTableViewCell?.isHidden = true
    self.addSubview(self.outgoingVideoFileMessageSizingTableViewCell!)

    self.incomingGeneralUrlPreviewMessageTableViewCell = IncomingGeneralUrlPreviewMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? IncomingGeneralUrlPreviewMessageTableViewCell
    self.incomingGeneralUrlPreviewMessageTableViewCell?.frame = self.frame
    self.incomingGeneralUrlPreviewMessageTableViewCell?.isHidden = true
    self.addSubview(self.incomingGeneralUrlPreviewMessageTableViewCell!)

    self.outgoingGeneralUrlPreviewMessageTableViewCell = OutgoingGeneralUrlPreviewMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? OutgoingGeneralUrlPreviewMessageTableViewCell
    self.outgoingGeneralUrlPreviewMessageTableViewCell?.frame = self.frame
    self.outgoingGeneralUrlPreviewMessageTableViewCell?.isHidden = true
    self.addSubview(self.outgoingGeneralUrlPreviewMessageTableViewCell!)

    self.outgoingGeneralUrlPreviewTempMessageTableViewCell = OutgoingGeneralUrlPreviewTempMessageTableViewCell.nib().instantiate(withOwner: self, options: nil)[0] as? OutgoingGeneralUrlPreviewTempMessageTableViewCell
    self.outgoingGeneralUrlPreviewTempMessageTableViewCell?.frame = self.frame
    self.outgoingGeneralUrlPreviewTempMessageTableViewCell?.isHidden = true
    self.addSubview(self.outgoingGeneralUrlPreviewTempMessageTableViewCell!)
  }

  func scrollToBottom(force: Bool) {
    if self.messages.count == 0 {
      return
    }

    if self.scrollLock == true && force == false {
      return
    }

    self.chattingTableView.scrollToRow(at: IndexPath(row: self.messages.count - 1, section: 0), at: UITableViewScrollPosition.bottom, animated: false)
  }

  func scrollToPosition(position: Int) {
    if self.messages.count == 0 {
      return
    }

    self.chattingTableView.scrollToRow(at: IndexPath(row: position, section: 0), at: UITableViewScrollPosition.top, animated: false)
  }

  func startTypingIndicator(text: String) {
    // Typing indicator
    self.typingIndicatorContainerView.isHidden = false
    self.typingIndicatorLabel.text = text

    self.typingIndicatorContainerViewHeight.constant = 26.0
    self.typingIndicatorImageHeight.constant = 26.0
    self.typingIndicatorContainerView.layoutIfNeeded()

    if self.typingIndicatorImageView.isAnimating == false {
      var typingImages: [UIImage] = []
      for i in 1 ... 50 {
        let typingImageFrameName = String(format: "%02d", i)
        typingImages.append(UIImage(named: typingImageFrameName)!)
      }
      self.typingIndicatorImageView.animationImages = typingImages
      self.typingIndicatorImageView.animationDuration = 1.5

      DispatchQueue.main.async {
        self.typingIndicatorImageView.startAnimating()
      }
    }
  }

  func endTypingIndicator() {
    DispatchQueue.main.async {
      self.typingIndicatorImageView.stopAnimating()
    }

    self.typingIndicatorContainerView.isHidden = true
    self.typingIndicatorContainerViewHeight.constant = 0
    self.typingIndicatorImageHeight.constant = 0

    self.typingIndicatorContainerView.layoutIfNeeded()
  }

  // MARK: UITextViewDelegate
  func textViewDidChange(_ textView: UITextView) {
    if textView == self.messageTextView {
      if textView.text.characters.count > 0 {
        self.placeholderLabel.isHidden = true
        if self.delegate != nil {
          self.delegate?.startTyping(view: self)
        }
      } else {
        self.placeholderLabel.isHidden = false
        if self.delegate != nil {
          self.delegate?.endTyping(view: self)
        }
      }
    }
  }

  // MARK: UITableViewDelegate
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    self.stopMeasuringVelocity = false
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    self.stopMeasuringVelocity = true
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView == self.chattingTableView {
      if self.stopMeasuringVelocity == false {
        let currentOffset = scrollView.contentOffset
        let currentTime = NSDate.timeIntervalSinceReferenceDate

        let timeDiff = currentTime - self.lastOffsetCapture
        if timeDiff > 0.1 {
          let distance = currentOffset.y - self.lastOffset.y
          let scrollSpeedNotAbs = distance * 10 / 1000
          let scrollSpeed = fabs(scrollSpeedNotAbs)
          if scrollSpeed > 0.5 {
            self.isScrollingFast = true
          } else {
            self.isScrollingFast = false
          }

          self.lastOffset = currentOffset
          self.lastOffsetCapture = currentTime
        }

        if self.isScrollingFast {
          if self.delegate != nil {
            self.delegate?.hideKeyboardWhenFastScrolling(view: self)
          }
        }
      }

      if scrollView.contentOffset.y + scrollView.frame.size.height + self.lastMessageHeight < scrollView.contentSize.height {
        self.scrollLock = true
      } else {
        self.scrollLock = false
      }

      if scrollView.contentOffset.y == 0 {
        if self.messages.count > 0 && self.initialLoading == false {
          if self.delegate != nil {
            self.delegate?.loadMoreMessage(view: self)
          }
        }
      }
    }
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    var height: CGFloat = 0

    let msg = self.messages[indexPath.row]

    if msg is SBDUserMessage {
      let userMessage = msg as! SBDUserMessage
      let sender = userMessage.sender

      if sender?.userId == SBDMain.getCurrentUser()?.userId {
        // Outgoing
        if userMessage.customType == "url_preview" {
          if indexPath.row > 0 {
            self.outgoingGeneralUrlPreviewMessageTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
          } else {
            self.outgoingGeneralUrlPreviewMessageTableViewCell?.setPreviousMessage(aPrevMessage: nil)
          }
          self.outgoingGeneralUrlPreviewMessageTableViewCell?.setModel(aMessage: userMessage)
          height = (self.outgoingGeneralUrlPreviewMessageTableViewCell?.getHeightOfViewCell())!
        } else {
          if indexPath.row > 0 {
            self.outgoingUserMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
          } else {
            self.outgoingUserMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
          }
          self.outgoingUserMessageSizingTableViewCell?.setModel(aMessage: userMessage)
          height = (self.outgoingUserMessageSizingTableViewCell?.getHeightOfViewCell())!
        }
      } else {
        // Incoming
        if userMessage.customType == "url_preview" {
          if indexPath.row > 0 {
            self.incomingGeneralUrlPreviewMessageTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
          } else {
            self.incomingGeneralUrlPreviewMessageTableViewCell?.setPreviousMessage(aPrevMessage: nil)
          }
          self.incomingGeneralUrlPreviewMessageTableViewCell?.setModel(aMessage: userMessage)
          height = CGFloat((self.incomingGeneralUrlPreviewMessageTableViewCell?.getHeightOfViewCell())!)
        } else {
          if indexPath.row > 0 {
            self.incomingUserMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
          } else {
            self.incomingUserMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
          }
          self.incomingUserMessageSizingTableViewCell?.setModel(aMessage: userMessage)
          height = (self.incomingUserMessageSizingTableViewCell?.getHeightOfViewCell())!
        }
      }
    } else if msg is SBDFileMessage {
      let fileMessage = msg as! SBDFileMessage
      let sender = fileMessage.sender

      if sender?.userId == SBDMain.getCurrentUser()?.userId {
        // Outgoing
        if fileMessage.type.hasPrefix("video") {
          if indexPath.row > 0 {
            self.outgoingVideoFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
          } else {
            self.outgoingVideoFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
          }
          self.outgoingVideoFileMessageSizingTableViewCell?.setModel(aMessage: fileMessage)
          height = (self.outgoingVideoFileMessageSizingTableViewCell?.getHeightOfViewCell())!
        } else if fileMessage.type.hasPrefix("audio") {
          if indexPath.row > 0 {
            self.outgoingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
          } else {
            self.outgoingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
          }
          self.outgoingFileMessageSizingTableViewCell?.setModel(aMessage: fileMessage)
          height = (self.outgoingFileMessageSizingTableViewCell?.getHeightOfViewCell())!
        } else if fileMessage.type.hasPrefix("image") {
          if indexPath.row > 0 {
            self.outgoingImageFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
          } else {
            self.outgoingImageFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
          }
          self.outgoingImageFileMessageSizingTableViewCell?.setModel(aMessage: fileMessage)
          height = (self.outgoingImageFileMessageSizingTableViewCell?.getHeightOfViewCell())!
        } else {
          if indexPath.row > 0 {
            self.outgoingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
          } else {
            self.outgoingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
          }
          self.outgoingFileMessageSizingTableViewCell?.setModel(aMessage: fileMessage)
          height = (self.outgoingFileMessageSizingTableViewCell?.getHeightOfViewCell())!
        }
      } else {
        // Incoming
        if fileMessage.type.hasPrefix("video") {
          if indexPath.row > 0 {
            self.incomingVideoFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
          } else {
            self.incomingVideoFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
          }
          self.incomingVideoFileMessageSizingTableViewCell?.setModel(aMessage: fileMessage)
          height = (self.incomingVideoFileMessageSizingTableViewCell?.getHeightOfViewCell())!
        } else if fileMessage.type.hasPrefix("audio") {
          if indexPath.row > 0 {
            self.incomingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
          } else {
            self.incomingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
          }
          self.incomingFileMessageSizingTableViewCell?.setModel(aMessage: fileMessage)
          height = (self.incomingFileMessageSizingTableViewCell?.getHeightOfViewCell())!
        } else if fileMessage.type.hasPrefix("image") {
          if indexPath.row > 0 {
            self.incomingImageFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
          } else {
            self.incomingImageFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
          }
          self.incomingImageFileMessageSizingTableViewCell?.setModel(aMessage: fileMessage)
          height = (self.incomingImageFileMessageSizingTableViewCell?.getHeightOfViewCell())!
        } else {
          if indexPath.row > 0 {
            self.incomingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
          } else {
            self.incomingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
          }
          self.incomingFileMessageSizingTableViewCell?.setModel(aMessage: fileMessage)
          height = (self.incomingFileMessageSizingTableViewCell?.getHeightOfViewCell())!
        }
      }
    } else if msg is SBDAdminMessage {
      let adminMessage = msg as! SBDAdminMessage
      if indexPath.row > 0 {
        self.neutralMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
      } else {
        self.neutralMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
      }

      self.neutralMessageSizingTableViewCell?.setModel(aMessage: adminMessage)
      height = (self.neutralMessageSizingTableViewCell?.getHeightOfViewCell())!
    } else if msg is OutgoingGeneralUrlPreviewTempModel {
      let tempModel: OutgoingGeneralUrlPreviewTempModel = msg as! OutgoingGeneralUrlPreviewTempModel
      if indexPath.row > 0 {
        self.outgoingGeneralUrlPreviewTempMessageTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
      } else {
        self.outgoingGeneralUrlPreviewTempMessageTableViewCell?.setPreviousMessage(aPrevMessage: nil)
      }
      self.outgoingGeneralUrlPreviewTempMessageTableViewCell?.setModel(aMessage: tempModel)
      height = (self.outgoingGeneralUrlPreviewTempMessageTableViewCell?.getHeightOfViewCell())!
    }

    if self.messages.count > 0 && self.messages.count - 1 == indexPath.row {
      self.lastMessageHeight = height
    }

    return height
  }

  /*
   func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
   var height: CGFloat = 0

   let msg = self.messages[indexPath.row]

   if msg is SBDUserMessage {
   let userMessage = msg as! SBDUserMessage
   let sender = userMessage.sender

   if sender?.userId == SBDMain.getCurrentUser()?.userId {
   // Outgoing
   if indexPath.row > 0 {
   self.outgoingUserMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
   }
   else {
   self.outgoingUserMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
   }
   self.outgoingUserMessageSizingTableViewCell?.setModel(aMessage: userMessage)
   height = (self.outgoingUserMessageSizingTableViewCell?.getHeightOfViewCell())!
   }
   else {
   // Incoming
   if indexPath.row > 0 {
   self.incomingUserMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
   }
   else {
   self.incomingUserMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
   }
   self.incomingUserMessageSizingTableViewCell?.setModel(aMessage: userMessage)
   height = (self.incomingUserMessageSizingTableViewCell?.getHeightOfViewCell())!
   }
   }
   else if msg is SBDFileMessage {
   let fileMessage = msg as! SBDFileMessage
   let sender = fileMessage.sender

   if sender?.userId == SBDMain.getCurrentUser()?.userId {
   // Outgoing
   if fileMessage.type.hasPrefix("video") {
   if indexPath.row > 0 {
   self.outgoingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
   }
   else {
   self.outgoingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
   }
   self.outgoingFileMessageSizingTableViewCell?.setModel(aMessage: fileMessage)
   height = (self.outgoingFileMessageSizingTableViewCell?.getHeightOfViewCell())!
   }
   else if fileMessage.type.hasPrefix("audio") {
   if indexPath.row > 0 {
   self.outgoingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
   }
   else {
   self.outgoingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
   }
   self.outgoingFileMessageSizingTableViewCell?.setModel(aMessage: fileMessage)
   height = (self.outgoingFileMessageSizingTableViewCell?.getHeightOfViewCell())!
   }
   else if fileMessage.type.hasPrefix("image") {
   if indexPath.row > 0 {
   self.outgoingImageFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
   }
   else {
   self.outgoingImageFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
   }
   self.outgoingImageFileMessageSizingTableViewCell?.setModel(aMessage: fileMessage)
   height = (self.outgoingImageFileMessageSizingTableViewCell?.getHeightOfViewCell())!
   }
   else {
   if indexPath.row > 0 {
   self.outgoingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
   }
   else {
   self.outgoingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
   }
   self.outgoingFileMessageSizingTableViewCell?.setModel(aMessage: fileMessage)
   height = (self.outgoingFileMessageSizingTableViewCell?.getHeightOfViewCell())!
   }
   }
   else {
   // Incoming
   if fileMessage.type.hasPrefix("video") {
   if indexPath.row > 0 {
   self.incomingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
   }
   else {
   self.incomingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
   }
   self.incomingFileMessageSizingTableViewCell?.setModel(aMessage: fileMessage)
   height = (self.incomingFileMessageSizingTableViewCell?.getHeightOfViewCell())!
   }
   else if fileMessage.type.hasPrefix("audio") {
   if indexPath.row > 0 {
   self.incomingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
   }
   else {
   self.incomingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
   }
   self.incomingFileMessageSizingTableViewCell?.setModel(aMessage: fileMessage)
   height = (self.incomingFileMessageSizingTableViewCell?.getHeightOfViewCell())!
   }
   else if fileMessage.type.hasPrefix("image") {
   if indexPath.row > 0 {
   self.incomingImageFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
   }
   else {
   self.incomingImageFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
   }
   self.incomingImageFileMessageSizingTableViewCell?.setModel(aMessage: fileMessage)
   height = (self.incomingImageFileMessageSizingTableViewCell?.getHeightOfViewCell())!
   }
   else {
   if indexPath.row > 0 {
   self.incomingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
   }
   else {
   self.incomingFileMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
   }
   self.incomingFileMessageSizingTableViewCell?.setModel(aMessage: fileMessage)
   height = (self.incomingFileMessageSizingTableViewCell?.getHeightOfViewCell())!
   }
   }
   }
   else if msg is SBDAdminMessage {
   let adminMessage = msg as! SBDAdminMessage
   if indexPath.row > 0 {
   self.neutralMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
   }
   else {
   self.neutralMessageSizingTableViewCell?.setPreviousMessage(aPrevMessage: nil)
   }

   self.neutralMessageSizingTableViewCell?.setModel(aMessage: adminMessage)
   height = (self.neutralMessageSizingTableViewCell?.getHeightOfViewCell())!
   }

   if self.messages.count > 0 && self.messages.count - 1 == indexPath.row {
   self.lastMessageHeight = height
   }

   return height
   }
   */

  func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
    return 0
  }

  func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
    return 0
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
  }

  // MARK: UITableViewDataSource
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.messages.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var cell: UITableViewCell?

    let msg = self.messages[indexPath.row]

    if msg is SBDUserMessage {
      let userMessage = msg as! SBDUserMessage
      let sender = userMessage.sender

      if sender?.userId == SBDMain.getCurrentUser()?.userId {
        handleOutgoing(userMessage: userMessage, &cell, tableView, indexPath)
      } else {
        handleIncoming(userMessage: userMessage, &cell, tableView, indexPath)
      }
    } else if msg is SBDFileMessage {
      let fileMessage = msg as! SBDFileMessage
      let sender = fileMessage.sender

      if sender?.userId == SBDMain.getCurrentUser()?.userId {
        handleOutgoing(fileMessage: fileMessage, &cell, tableView, indexPath)
      } else {
        handleIncoming(fileMessage: fileMessage, &cell, tableView, indexPath)
      }
    } else if msg is SBDAdminMessage {
      let adminMessage = msg as! SBDAdminMessage

      build(adminMessageCell: &cell, tableView, indexPath, adminMessage)
    } else if msg is OutgoingGeneralUrlPreviewTempModel {
      let model = msg as! OutgoingGeneralUrlPreviewTempModel

      buildOutgoing(generalUrlPreviewCell: &cell, tableView, indexPath, model)
    }

    return cell!
  }

  // MARK: Outgoing message cells

  fileprivate func buildOutgoing(urlPreviewCell: inout UITableViewCell?, _ tableView: UITableView, _ indexPath: IndexPath, _ userMessage: SBDUserMessage) {
    urlPreviewCell = tableView.dequeueReusableCell(withIdentifier: OutgoingGeneralUrlPreviewMessageTableViewCell.cellReuseIdentifier())
    urlPreviewCell?.frame = CGRect(x: (urlPreviewCell?.frame.origin.x)!, y: (urlPreviewCell?.frame.origin.y)!, width: (urlPreviewCell?.frame.size.width)!, height: (urlPreviewCell?.frame.size.height)!)
    let cell = urlPreviewCell as! OutgoingGeneralUrlPreviewMessageTableViewCell
    if indexPath.row > 0 {
      cell.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
    } else {
      cell.setPreviousMessage(aPrevMessage: nil)
    }
    cell.setModel(aMessage: userMessage)
    cell.delegate = self.delegate

    let imageUrl = cell.previewData["image"] as! String
    let ext = (imageUrl as NSString).pathExtension

    cell.previewThumbnailImageView.image = nil
    cell.previewThumbnailImageView.animatedImage = nil
    cell.previewThumbnailLoadingIndicator.isHidden = false
    cell.previewThumbnailLoadingIndicator.startAnimating()
    if imageUrl.count > 0 {
      if ext.lowercased().hasPrefix("gif") {
        cell.previewThumbnailImageView.setAnimatedImageWithURL(url: URL(string: imageUrl)!, success: { image in
          DispatchQueue.main.async {
            cell.previewThumbnailImageView.animatedImage = image
            cell.previewThumbnailLoadingIndicator.isHidden = true
            cell.previewThumbnailLoadingIndicator.stopAnimating()
          }
        }, failure: { error in
          DispatchQueue.main.async {
            cell.previewThumbnailLoadingIndicator.isHidden = true
            cell.previewThumbnailLoadingIndicator.stopAnimating()
          }
        })
      }
    } else {
      Alamofire.request(imageUrl, method: .get).responseImage { response in
        guard let image = response.result.value else {
          DispatchQueue.main.async {
            cell.previewThumbnailLoadingIndicator.isHidden = true
            cell.previewThumbnailLoadingIndicator.stopAnimating()
          }

          return
        }

        DispatchQueue.main.async {
          cell.previewThumbnailImageView.image = image
          cell.previewThumbnailLoadingIndicator.isHidden = true
          cell.previewThumbnailLoadingIndicator.stopAnimating()
        }
      }
    }

    if self.preSendMessages[userMessage.requestId!] != nil {
      cell.showSendingStatus()
    } else {
      if self.resendableMessages[userMessage.requestId!] != nil {
        cell.showMessageControlButton()
        //                            urlPreviewCell.showFailedStatus()
      } else {
        cell.showMessageDate()
        cell.showUnreadCount()
      }
    }
  }

  fileprivate func buildOutgoing(userMessageCell: inout UITableViewCell?, _ tableView: UITableView, _ indexPath: IndexPath, _ userMessage: SBDUserMessage) {
    userMessageCell = tableView.dequeueReusableCell(withIdentifier: OutgoingUserMessageTableViewCell.cellReuseIdentifier())
    userMessageCell?.frame = CGRect(x: (userMessageCell?.frame.origin.x)!, y: (userMessageCell?.frame.origin.y)!, width: (userMessageCell?.frame.size.width)!, height: (userMessageCell?.frame.size.height)!)
    let cell2 = userMessageCell as! OutgoingUserMessageTableViewCell
    if indexPath.row > 0 {
      cell2.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
    } else {
      cell2.setPreviousMessage(aPrevMessage: nil)
    }
    cell2.setModel(aMessage: userMessage)
    cell2.delegate = self.delegate

    if self.preSendMessages[userMessage.requestId!] != nil {
      cell2.showSendingStatus()
    } else {
      if self.resendableMessages[userMessage.requestId!] != nil {
        cell2.showMessageControlButton()
        //                            userMessageCell.showFailedStatus()
      } else {
        cell2.showMessageDate()
        cell2.showUnreadCount()
      }
    }
  }

  fileprivate func handleOutgoing(userMessage: SBDUserMessage, _ cell: inout UITableViewCell?, _ tableView: UITableView, _ indexPath: IndexPath) {
    if userMessage.customType == "url_preview" {
      buildOutgoing(urlPreviewCell: &cell, tableView, indexPath, userMessage)
    } else {
      buildOutgoing(userMessageCell: &cell, tableView, indexPath, userMessage)
    }
  }

  fileprivate func buildOutgoing(videoMessageCell: inout UITableViewCell?, _ tableView: UITableView, _ indexPath: IndexPath, _ fileMessage: SBDFileMessage) {
    videoMessageCell = tableView.dequeueReusableCell(withIdentifier: OutgoingVideoFileMessageTableViewCell.cellReuseIdentifier())
    videoMessageCell?.frame = CGRect(x: (videoMessageCell?.frame.origin.x)!, y: (videoMessageCell?.frame.origin.y)!, width: (videoMessageCell?.frame.size.width)!, height: (videoMessageCell?.frame.size.height)!)
    let cell = videoMessageCell as! OutgoingVideoFileMessageTableViewCell
    if indexPath.row > 0 {
      cell.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
    } else {
      cell.setPreviousMessage(aPrevMessage: nil)
    }
    cell.setModel(aMessage: fileMessage)
    cell.delegate = self.delegate

    if self.preSendMessages[fileMessage.requestId!] != nil {
      cell.showSendingStatus()
    } else {
      if self.resendableMessages[fileMessage.requestId!] != nil {
        cell.showMessageControlButton()
        //                            (cell as! OutgoingVideoFileMessageTableViewCell).showFailedStatus()
      } else {
        cell.showMessageDate()
        cell.showUnreadCount()
      }
    }
  }

  fileprivate func buildOutgoing(audioMessageCell: inout UITableViewCell?, _ tableView: UITableView, _ indexPath: IndexPath, _ fileMessage: SBDFileMessage) {
    audioMessageCell = tableView.dequeueReusableCell(withIdentifier: OutgoingFileMessageTableViewCell.cellReuseIdentifier())
    audioMessageCell?.frame = CGRect(x: (audioMessageCell?.frame.origin.x)!, y: (audioMessageCell?.frame.origin.y)!, width: (audioMessageCell?.frame.size.width)!, height: (audioMessageCell?.frame.size.height)!)
    let cell = audioMessageCell as! OutgoingFileMessageTableViewCell
    if indexPath.row > 0 {
      cell.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
    } else {
      cell.setPreviousMessage(aPrevMessage: nil)
    }
    cell.setModel(aMessage: fileMessage)
    cell.delegate = self.delegate

    if self.preSendMessages[fileMessage.requestId!] != nil {
      cell.showSendingStatus()
    } else {
      if self.resendableMessages[fileMessage.requestId!] != nil {
        cell.showMessageControlButton()
        //                            (cell as! OutgoingFileMessageTableViewCell).showFailedStatus()
      } else {
        cell.showMessageDate()
        cell.showUnreadCount()
      }
    }
  }

  fileprivate func handleOutgoing(gifUrl: String, _ cell: OutgoingImageFileMessageTableViewCell, _ tableView: UITableView, _ indexPath: IndexPath) {
    cell.fileImageView.setAnimatedImageWithURL(url: URL(string: gifUrl)!, success: { image in
      DispatchQueue.main.async {
        let updateCell = tableView.cellForRow(at: indexPath) as? OutgoingImageFileMessageTableViewCell
        if updateCell != nil {
          cell.fileImageView.animatedImage = image
          cell.imageLoadingIndicator.stopAnimating()
          cell.imageLoadingIndicator.isHidden = true
        }
      }
    }, failure: { error in
      DispatchQueue.main.async {
        let updateCell = tableView.cellForRow(at: indexPath) as? OutgoingImageFileMessageTableViewCell
        if updateCell != nil {
          cell.fileImageView.af_setImage(withURL: URL(string: gifUrl)!)
          cell.imageLoadingIndicator.stopAnimating()
          cell.imageLoadingIndicator.isHidden = true
        }
      }
    })
  }

  fileprivate func handleOutgoing(staticImageUrl: String, _ cell: OutgoingImageFileMessageTableViewCell, _ tableView: UITableView, _ indexPath: IndexPath) {
    let request = URLRequest(url: URL(string: staticImageUrl)!)
    cell.fileImageView.af_setImage(withURLRequest: request, placeholderImage: nil, filter: nil, progress: nil, progressQueue: DispatchQueue.main, imageTransition: UIImageView.ImageTransition.noTransition, runImageTransitionIfCached: false, completion: { response in
      if response.result.error != nil {
        DispatchQueue.main.async {
          let updateCell = tableView.cellForRow(at: indexPath) as? OutgoingImageFileMessageTableViewCell
          if updateCell != nil {
            cell.fileImageView.image = nil
            cell.imageLoadingIndicator.isHidden = true
            cell.imageLoadingIndicator.stopAnimating()
          }
        }
      } else {
        DispatchQueue.main.async {
          let updateCell = tableView.cellForRow(at: indexPath) as? OutgoingImageFileMessageTableViewCell
          if updateCell != nil {
            cell.fileImageView.image = response.result.value
            cell.imageLoadingIndicator.isHidden = true
            cell.imageLoadingIndicator.stopAnimating()
          }
        }
      }
    })
  }

  fileprivate func buildOutgoing(imageMessageCell: inout UITableViewCell?, _ tableView: UITableView, _ indexPath: IndexPath, _ fileMessage: SBDFileMessage) {
    imageMessageCell = tableView.dequeueReusableCell(withIdentifier: OutgoingImageFileMessageTableViewCell.cellReuseIdentifier())
    imageMessageCell?.frame = CGRect(x: (imageMessageCell?.frame.origin.x)!, y: (imageMessageCell?.frame.origin.y)!, width: (imageMessageCell?.frame.size.width)!, height: (imageMessageCell?.frame.size.height)!)
    let cell = imageMessageCell as! OutgoingImageFileMessageTableViewCell
    if indexPath.row > 0 {
      cell.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
    } else {
      cell.setPreviousMessage(aPrevMessage: nil)
    }
    cell.setModel(aMessage: fileMessage)
    cell.delegate = self.delegate

    if self.preSendMessages[fileMessage.requestId!] != nil {
      cell.showSendingStatus()
      cell.hasImageCacheData = true
      cell.setImageData(data: self.preSendFileData[fileMessage.requestId!]!["data"] as! Data, type: self.preSendFileData[fileMessage.requestId!]!["type"] as! String)
    } else {
      if self.resendableMessages[fileMessage.requestId!] != nil {
        cell.showMessageControlButton()
        //                            (cell as! OutgoingImageFileMessageTableViewCell).showFailedStatus()
        cell.setImageData(data: self.resendableFileData[fileMessage.requestId!]?["data"] as! Data, type: self.resendableFileData[fileMessage.requestId!]?["type"] as! String)
        cell.hasImageCacheData = true
      } else {
        if fileMessage.url.count > 0 && self.preSendFileData[fileMessage.requestId!] != nil {
          cell.setImageData(data: self.preSendFileData[fileMessage.requestId!]?["data"] as! Data, type: self.preSendFileData[fileMessage.requestId!]?["type"] as! String)
          cell.hasImageCacheData = true
          self.preSendFileData.removeValue(forKey: fileMessage.requestId!)
        } else {
          cell.hasImageCacheData = false

          var fileImageUrl = ""
          if let thumbnails = fileMessage.thumbnails {
            let thumbnailsCount = thumbnails.count
            if thumbnailsCount > 0 && fileMessage.type != "image/gif" {
              fileImageUrl = thumbnails[0].url
            } else {
              fileImageUrl = fileMessage.url
            }
          }

          cell.fileImageView.image = nil
          cell.fileImageView.animatedImage = nil

          if fileMessage.type == "image/gif" {
            handleOutgoing(gifUrl: fileImageUrl, cell, tableView, indexPath)
          } else {
            handleOutgoing(staticImageUrl: fileImageUrl, cell, tableView, indexPath)
          }
        }
        cell.showMessageDate()
        cell.showUnreadCount()
      }
    }
  }

  fileprivate func buildOutgoing(fileMessageCell: inout UITableViewCell?, _ tableView: UITableView, _ indexPath: IndexPath, _ fileMessage: SBDFileMessage) {
    fileMessageCell = tableView.dequeueReusableCell(withIdentifier: OutgoingFileMessageTableViewCell.cellReuseIdentifier())
    fileMessageCell?.frame = CGRect(x: (fileMessageCell?.frame.origin.x)!, y: (fileMessageCell?.frame.origin.y)!, width: (fileMessageCell?.frame.size.width)!, height: (fileMessageCell?.frame.size.height)!)
    let cell = fileMessageCell as! OutgoingFileMessageTableViewCell
    if indexPath.row > 0 {
      cell.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
    } else {
      cell.setPreviousMessage(aPrevMessage: nil)
    }
    cell.setModel(aMessage: fileMessage)
    cell.delegate = self.delegate

    if self.preSendMessages[fileMessage.requestId!] != nil {
      cell.showSendingStatus()
    } else {
      if self.resendableMessages[fileMessage.requestId!] != nil {
        cell.showMessageControlButton()
        //                            cell.showFailedStatus()
      } else {
        cell.showMessageDate()
        cell.showUnreadCount()
      }
    }
  }

  fileprivate func handleOutgoing(fileMessage: SBDFileMessage, _ cell: inout UITableViewCell?, _ tableView: UITableView, _ indexPath: IndexPath) {
    // Outgoing
    if fileMessage.type.hasPrefix("video") {
      buildOutgoing(videoMessageCell: &cell, tableView, indexPath, fileMessage)
    } else if fileMessage.type.hasPrefix("audio") {
      buildOutgoing(audioMessageCell: &cell, tableView, indexPath, fileMessage)
    } else if fileMessage.type.hasPrefix("image") {
      buildOutgoing(imageMessageCell: &cell, tableView, indexPath, fileMessage)
    } else {
      buildOutgoing(fileMessageCell: &cell, tableView, indexPath, fileMessage)
    }
  }

  fileprivate func build(adminMessageCell: inout UITableViewCell?, _ tableView: UITableView, _ indexPath: IndexPath, _ adminMessage: SBDAdminMessage) {
    adminMessageCell = tableView.dequeueReusableCell(withIdentifier: NeutralMessageTableViewCell.cellReuseIdentifier())
    adminMessageCell?.frame = CGRect(x: (adminMessageCell?.frame.origin.x)!, y: (adminMessageCell?.frame.origin.y)!, width: (adminMessageCell?.frame.size.width)!, height: (adminMessageCell?.frame.size.height)!)
    let cell = adminMessageCell as! NeutralMessageTableViewCell
    if indexPath.row > 0 {
      cell.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
    } else {
      cell.setPreviousMessage(aPrevMessage: nil)
    }

    cell.setModel(aMessage: adminMessage)
  }

  fileprivate func buildOutgoing(generalUrlPreviewCell: inout UITableViewCell?, _ tableView: UITableView, _ indexPath: IndexPath, _ model: OutgoingGeneralUrlPreviewTempModel) {
    generalUrlPreviewCell = tableView.dequeueReusableCell(withIdentifier: OutgoingGeneralUrlPreviewTempMessageTableViewCell.cellReuseIdentifier())
    generalUrlPreviewCell?.frame = CGRect(x: (generalUrlPreviewCell?.frame.origin.x)!, y: (generalUrlPreviewCell?.frame.origin.y)!, width: (generalUrlPreviewCell?.frame.size.width)!, height: (generalUrlPreviewCell?.frame.size.height)!)
    let cell = generalUrlPreviewCell as! OutgoingGeneralUrlPreviewTempMessageTableViewCell
    if indexPath.row > 0 {
      cell.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
    } else {
      cell.setPreviousMessage(aPrevMessage: nil)
    }

    cell.setModel(aMessage: model)
  }

  // MARK: Incoming message cells

  fileprivate func buildIncoming(urlPreviewCell: inout UITableViewCell?, _ tableView: UITableView, _ indexPath: IndexPath, _ userMessage: SBDUserMessage) {
    urlPreviewCell = tableView.dequeueReusableCell(withIdentifier: IncomingGeneralUrlPreviewMessageTableViewCell.cellReuseIdentifier())
    urlPreviewCell?.frame = CGRect(x: (urlPreviewCell?.frame.origin.x)!, y: (urlPreviewCell?.frame.origin.y)!, width: (urlPreviewCell?.frame.size.width)!, height: (urlPreviewCell?.frame.size.height)!)
    let cell = urlPreviewCell as! IncomingGeneralUrlPreviewMessageTableViewCell
    if indexPath.row > 0 {
      cell.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
    } else {
      cell.setPreviousMessage(aPrevMessage: nil)
    }
    cell.setModel(aMessage: userMessage)
    cell.delegate = self.delegate

    let imageUrl = cell.previewData["image"] as! String
    let ext = (imageUrl as NSString).pathExtension

    cell.previewThumbnailImageView.image = nil
    cell.previewThumbnailImageView.animatedImage = nil
    cell.previewThumbnailLoadingIndicator.isHidden = false
    cell.previewThumbnailLoadingIndicator.startAnimating()

    if imageUrl.count > 0 {
      if ext.lowercased().hasPrefix("gif") {
        cell.previewThumbnailImageView.setAnimatedImageWithURL(url: URL(string: imageUrl)!, success: { image in
          DispatchQueue.main.async {
            cell.previewThumbnailImageView.image = nil
            cell.previewThumbnailImageView.animatedImage = nil
            cell.previewThumbnailImageView.animatedImage = image
            cell.previewThumbnailLoadingIndicator.isHidden = true
            cell.previewThumbnailLoadingIndicator.stopAnimating()
          }
        }, failure: { error in
          DispatchQueue.main.async {
            cell.previewThumbnailLoadingIndicator.isHidden = true
            cell.previewThumbnailLoadingIndicator.stopAnimating()
          }
        })
      } else {
        Alamofire.request(imageUrl, method: .get).responseImage { response in
          guard let image = response.result.value else {
            DispatchQueue.main.async {
              cell.previewThumbnailLoadingIndicator.isHidden = true
              cell.previewThumbnailLoadingIndicator.stopAnimating()
            }

            return
          }

          DispatchQueue.main.async {
            cell.previewThumbnailImageView.image = image
            cell.previewThumbnailLoadingIndicator.isHidden = true
            cell.previewThumbnailLoadingIndicator.stopAnimating()
          }
        }
      }
    }
  }

  fileprivate func buildIncoming(userMessageCell: inout UITableViewCell?, _ tableView: UITableView, _ indexPath: IndexPath, _ userMessage: SBDUserMessage) {
    userMessageCell = tableView.dequeueReusableCell(withIdentifier: IncomingUserMessageTableViewCell.cellReuseIdentifier())
    userMessageCell?.frame = CGRect(x: (userMessageCell?.frame.origin.x)!, y: (userMessageCell?.frame.origin.y)!, width: (userMessageCell?.frame.size.width)!, height: (userMessageCell?.frame.size.height)!)
    let cell = userMessageCell as! IncomingUserMessageTableViewCell
    if indexPath.row > 0 {
      cell.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
    } else {
      cell.setPreviousMessage(aPrevMessage: nil)
    }
    cell.setModel(aMessage: userMessage)
    cell.delegate = self.delegate
  }

  fileprivate func handleIncoming(userMessage: SBDUserMessage, _ cell: inout UITableViewCell?, _ tableView: UITableView, _ indexPath: IndexPath) {
    if userMessage.customType == "url_preview" {
      buildIncoming(urlPreviewCell: &cell, tableView, indexPath, userMessage)
    } else {
      buildIncoming(userMessageCell: &cell, tableView, indexPath, userMessage)
    }
  }

  fileprivate func buildIncoming(videoMessageCell: inout UITableViewCell?, _ tableView: UITableView, _ indexPath: IndexPath, _ fileMessage: SBDFileMessage) {
    videoMessageCell = tableView.dequeueReusableCell(withIdentifier: IncomingVideoFileMessageTableViewCell.cellReuseIdentifier())
    videoMessageCell?.frame = CGRect(x: (videoMessageCell?.frame.origin.x)!, y: (videoMessageCell?.frame.origin.y)!, width: (videoMessageCell?.frame.size.width)!, height: (videoMessageCell?.frame.size.height)!)
    let cell = videoMessageCell as! IncomingVideoFileMessageTableViewCell
    if indexPath.row > 0 {
      cell.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
    } else {
      cell.setPreviousMessage(aPrevMessage: nil)
    }
    cell.setModel(aMessage: fileMessage)
    cell.delegate = self.delegate
  }

  fileprivate func buildIncoming(audioMessageCell: inout UITableViewCell?, _ tableView: UITableView, _ indexPath: IndexPath, _ fileMessage: SBDFileMessage) {
    audioMessageCell = tableView.dequeueReusableCell(withIdentifier: IncomingFileMessageTableViewCell.cellReuseIdentifier())
    audioMessageCell?.frame = CGRect(x: (audioMessageCell?.frame.origin.x)!, y: (audioMessageCell?.frame.origin.y)!, width: (audioMessageCell?.frame.size.width)!, height: (audioMessageCell?.frame.size.height)!)
    let cell = audioMessageCell as! IncomingFileMessageTableViewCell
    if indexPath.row > 0 {
      cell.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
    } else {
      cell.setPreviousMessage(aPrevMessage: nil)
    }
    cell.setModel(aMessage: fileMessage)
    cell.delegate = self.delegate
  }

  fileprivate func handleIncoming(gifUrl: String, _ cell: IncomingImageFileMessageTableViewCell, _ tableView: UITableView, _ indexPath: IndexPath) {
    cell.imageLoadingIndicator.isHidden = false
    cell.imageLoadingIndicator.startAnimating()
    cell.fileImageView.setAnimatedImageWithURL(url: URL(string: gifUrl)!, success: { image in
      DispatchQueue.main.async {
        let updateCell = tableView.cellForRow(at: indexPath) as? IncomingImageFileMessageTableViewCell
        if updateCell != nil {
          cell.fileImageView.animatedImage = image
          cell.imageLoadingIndicator.stopAnimating()
          cell.imageLoadingIndicator.isHidden = true
        }
      }
    }, failure: { error in
      DispatchQueue.main.async {
        let updateCell = tableView.cellForRow(at: indexPath) as? IncomingImageFileMessageTableViewCell
        if updateCell != nil {
          cell.fileImageView.af_setImage(withURL: URL(string: gifUrl)!)
          cell.imageLoadingIndicator.stopAnimating()
          cell.imageLoadingIndicator.isHidden = true
        }
      }
    })
  }

  fileprivate func buildIncoming(imageMessageCell: inout UITableViewCell?, _ tableView: UITableView, _ indexPath: IndexPath, _ fileMessage: SBDFileMessage) {
    imageMessageCell = tableView.dequeueReusableCell(withIdentifier: IncomingImageFileMessageTableViewCell.cellReuseIdentifier())
    imageMessageCell?.frame = CGRect(x: (imageMessageCell?.frame.origin.x)!, y: (imageMessageCell?.frame.origin.y)!, width: (imageMessageCell?.frame.size.width)!, height: (imageMessageCell?.frame.size.height)!)
    let cell = imageMessageCell as! IncomingImageFileMessageTableViewCell
    if indexPath.row > 0 {
      cell.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
    } else {
      cell.setPreviousMessage(aPrevMessage: nil)
    }
    cell.setModel(aMessage: fileMessage)
    cell.delegate = self.delegate

    var fileImageUrl = ""
    if let thumbnails = fileMessage.thumbnails {
      let thumbnailsCount = thumbnails.count
      if thumbnailsCount > 0 && fileMessage.type != "image/gif" {
        fileImageUrl = thumbnails[0].url
      } else {
        fileImageUrl = fileMessage.url
      }
    }

    cell.fileImageView.image = nil
    cell.fileImageView.animatedImage = nil

    if fileMessage.type == "image/gif" {
      handleIncoming(gifUrl: fileImageUrl, cell, tableView, indexPath)
    }
  }

  fileprivate func buildIncoming(fileMessageCell: inout UITableViewCell?, _ tableView: UITableView, _ indexPath: IndexPath, _ fileMessage: SBDFileMessage) {
    fileMessageCell = tableView.dequeueReusableCell(withIdentifier: IncomingFileMessageTableViewCell.cellReuseIdentifier())
    fileMessageCell?.frame = CGRect(x: (fileMessageCell?.frame.origin.x)!, y: (fileMessageCell?.frame.origin.y)!, width: (fileMessageCell?.frame.size.width)!, height: (fileMessageCell?.frame.size.height)!)
    let cell = fileMessageCell as! IncomingFileMessageTableViewCell
    if indexPath.row > 0 {
      cell.setPreviousMessage(aPrevMessage: self.messages[indexPath.row - 1])
    } else {
      cell.setPreviousMessage(aPrevMessage: nil)
    }
    cell.setModel(aMessage: fileMessage)
    cell.delegate = self.delegate
  }

  fileprivate func handleIncoming(fileMessage: SBDFileMessage, _ cell: inout UITableViewCell?, _ tableView: UITableView, _ indexPath: IndexPath) {
    if fileMessage.type.hasPrefix("video") {
      buildIncoming(videoMessageCell: &cell, tableView, indexPath, fileMessage)
    } else if fileMessage.type.hasPrefix("audio") {
      buildIncoming(audioMessageCell: &cell, tableView, indexPath, fileMessage)
    } else if fileMessage.type.hasPrefix("image") {
      buildIncoming(imageMessageCell: &cell, tableView, indexPath, fileMessage)
    } else {
      buildIncoming(fileMessageCell: &cell, tableView, indexPath, fileMessage)
    }
  }

}

