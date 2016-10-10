//
//  MessageViewController.swift
//  knnect
//
//  Created by Chris Bayley on 6/8/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//
/*
 * Copyright (c) 2015 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */


import UIKit
import Firebase
import JSQMessagesViewController

class MessageViewController: JSQMessagesViewController {
    
    // MARK: Properties
    let rootReference = FIRDatabase.database().reference()
    var messageReference:FIRDatabaseReference? = FIRDatabase.database().reference().child("messages")
    var messages = [JSQMessage]()
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    let uid = FIRAuth.auth()?.currentUser!.uid
    var userConvoRef: FIRDatabaseReference?
    var otherUserConvoRef: FIRDatabaseReference?
    var uidToChat: String?
    var avatarOther: JSQMessageAvatarImageDataSource?
    var userIsTypingRef: FIRDatabaseReference?
    var usersTypingQuery: FIRDatabaseQuery?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.inputToolbar.contentView.leftBarButtonItem = nil
        self.getMessageRef(self.uidToChat!)
        showLoadEarlierMessagesHeader = true
        setupAvatars()
        setupBubbles()
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        observeMessages()
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.popViewControllerAnimated(false)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item] // 1
        if message.senderId == senderId { // 2
            return outgoingBubbleImageView
        } else { // 3
            return incomingBubbleImageView
        }
    }
    
  /** LOLOLOLOL DIS MIGHT BREAK PLS DELETE IF DOES**/
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        if(!messages.isEmpty){
            let messagesQuery = messageReference!.queryEndingAtValue(messages[0].date.timeIntervalSince1970).queryLimitedToFirst(25)
            
            var messageArray = [JSQMessage]()
            messagesQuery.observeSingleEventOfType(.Value, withBlock: {snapshot in
                
                for child in snapshot.children{
                    if (child.value!["date"] as! NSTimeInterval == self.messages[0].date.timeIntervalSince1970){
                        break
                    }
                    var id: String?
                    var text: String?
                    var date: NSDate?
                    id = child.value!["senderId"] as? String
                    text =  child.value!["text"] as? String
                    date = NSDate(timeIntervalSince1970: (child.value!["date"] as! NSTimeInterval))
                    let message = JSQMessage(senderId: id, senderDisplayName: self.senderDisplayName, date: date, text: text)
                    messageArray.append(message)
                }
                
                self.messages.insertContentsOf(messageArray, at: 0)
                self.finishReceivingMessage()
            })

        }
        
    }
    
    /** LOLOLOL ENDS HERE PLZ DELETE -- LUV CHARLES **/
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        
        if message.senderId == senderId { // 1
            cell.textView!.textColor = UIColor.whiteColor() // 2
        } else {
            cell.textView!.textColor = UIColor.blackColor() // 3
        }
        
        return cell
    }
    
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        
        return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        
        if indexPath.item == 0{
            return 20.00
        } else if (messages[indexPath.item].date.isLessThanDate(messages[indexPath.item-1].date.dateByAddingTimeInterval(100.0))){ //Change time interval between time stamps here
            return 0.0
        } else{
            return 20.00
        }
    }
    
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        let message = messages[indexPath.item]
        
        if message.senderId == senderId { // 1
            return nil
        } else {
            return self.avatarOther
        }
        
    }
    
    private func observeMessages() {
        
        let messagesQuery = messageReference!.queryLimitedToLast(25)
        
        messagesQuery.observeEventType(.ChildAdded, withBlock: {snapshot in
            
            var id: String?
            var text: String?
            var date: NSDate?
            id = snapshot.value!["senderId"] as? String
            text =  snapshot.value!["text"] as? String
            
            date = NSDate(timeIntervalSince1970: (snapshot.value!["date"] as! NSTimeInterval))
            self.addMessage(id!, text: text!, date: date!)
            
            self.userConvoRef!.child(self.uid!).child("read").setValue(true)
            
            self.finishReceivingMessage()
        })
    }
    
    func addMessage(id: String, text: String, date: NSDate) {
        
        let message = JSQMessage(senderId: id, senderDisplayName: senderDisplayName, date: date, text: text)
        messages.append(message)
    }
    
    override func textViewDidChange(textView: UITextView) {
        super.textViewDidChange(textView)
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        
        let itemRef = messageReference!.childByAutoId()
        let messageItem = [
            "text": text,
            "senderId": senderId,
            "date" : (date.timeIntervalSince1970)
        ]
        itemRef.setValue(messageItem)
        self.otherUserConvoRef!.child(self.uid!).child("read").setValue(false)
        self.otherUserConvoRef!.child(self.uid!).child("last-message").setValue(text)
        self.userConvoRef!.child(self.uidToChat!).child("last-message").setValue(text)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
    }
    
    
    private func setupBubbles() {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImageView = bubbleImageFactory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
        incomingBubbleImageView = bubbleImageFactory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    }
    
    
    
    private func setupAvatars() {
        //Setting up avatars
        
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero //No avatar set for self
        
        //Avatar set for other user
        
        let initials = self.title!.substringToIndex(self.title!.startIndex.advancedBy(1))
        
        self.avatarOther = JSQMessagesAvatarImageFactory.avatarImageWithUserInitials(initials, backgroundColor: UIColor.jsq_messageBubbleBlueColor(), textColor: UIColor.whiteColor(), font: UIFont.systemFontOfSize(16), diameter: UInt(kJSQMessagesCollectionViewAvatarSizeDefault))
        
        
    }
    
    
    
    //This sets up the message environment by taking the other user's uid and finding the corresponding messagekey. If
    // one does not already exist, it creates a new message key.
    
    func getMessageRef(uidToChat:String){
        self.userConvoRef = self.rootReference.child("user-info").child(self.uid!).child("messages")
        self.otherUserConvoRef = self.rootReference.child("user-info").child(self.uidToChat!).child("messages")
        
        userConvoRef!.observeSingleEventOfType(.Value, withBlock: {snapshot in
            
            for item in snapshot.children {
                
                if uidToChat == item.key {
                    self.messageReference = self.messageReference!.child(item.value["msgkey"] as! String)
                    self.userConvoRef!.child(self.uidToChat!).child("read").setValue(true)
                    return
                }
            }
            
            //create new messagekey
            self.messageReference = self.messageReference!.childByAutoId()
            let msgkey = self.messageReference!.key
            
            //adding messagekey ref to current member
            
            self.userConvoRef!.child(uidToChat).child("msgkey").setValue(msgkey)
            
            //Adding the messagekey ref to the other member of the chat
            let authRef = FIRAuth.auth()!
            let currentUid = authRef.currentUser!.uid
            self.rootReference.child("user-info").child(uidToChat).child("messages").child(currentUid).child("msgkey").setValue(msgkey)
            
            
        })
        
    }
    
    
    
    
}

extension NSDate {
    func isGreaterThanDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isGreater = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedDescending {
            isGreater = true
        }
        
        //Return Result
        return isGreater
    }
    func isLessThanDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isLess = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedAscending {
            isLess = true
        }
        
        //Return Result
        return isLess
    }
}
