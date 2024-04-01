//
//  MessagesViewController.swift
//  SendAvailability
//
//  Created by Zane Sabbagh on 3/31/24.
//

import UIKit
import SwiftUI
import Messages
import Foundation

struct ToDoListItem: Identifiable, Codable {
    var id: String
    var name: String
    var checked: Bool = false
    var checkedBy: String = ""
    var checkedAt: Int64 = 0
    
    init(name: String) {
        self.name = name
        self.id = UUID().uuidString
    }
}

class ToDoList: ObservableObject, Codable {
    @Published var name: String
    @Published var items: [ToDoListItem] = [ToDoListItem(name: "")]
    
    @Published var createdBy: String = ""
    
    enum CodingKeys: String, CodingKey {
        case name
        case createdBy
        case items
    }
    
    
}





@objc(MessagesViewController)
class MessagesViewController: MSMessagesAppViewController {
    
    private var messageView: MessageView? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        print("MSMessagesAppViewController.viewDidLoad")
        
        var localUserUuid = ""
        if activeConversation != nil {
            localUserUuid = activeConversation?.localParticipantIdentifier.uuidString ?? ""
        }
        
        
        if presentationStyle == .transcript {
            if activeConversation != nil {
                let message = activeConversation!.selectedMessage
                if message != nil {
                    messageView!.parseListFromURL(url: message!.url!)
                }
            }
        }
        
        // Get the UIKit view of your SwiftUI View
        self.addChildViewController()
    }
    
    private func addChildViewController() {
        let child = UIHostingController(rootView: self.messageView)
        
        child.view.translatesAutoresizingMaskIntoConstraints = false
        child.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(child.view)

        // Set the place where your view will be displayed
        let constraints = [
            child.view.topAnchor.constraint(equalTo: view.topAnchor),
            child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            child.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            child.view.heightAnchor.constraint(equalTo: view.heightAnchor)
        ]

        self.view.addConstraints(constraints)
    }
    
    func updateToDoList(list: ToDoList) {
        // update the message with the new to do list
        guard let conversation = activeConversation else { return }
        guard let message = conversation.selectedMessage else { return }
        
        // sort the list to put the checked items at the end
        list.sortItems()
        
        message.url = list.getUrl()
        
        /*
         Subsequent calls to this method replace any existing message in the input field.

         If the message was initialized using the session from an existing message, a new 
         message isn’t added to the transcript. Instead, the system takes the following steps
         as soon as the user sends the message:

         - The system moves the existing message to the bottom of the conversation transcript.
         - It updates the message with the new content.
         
         Source: https://developer.apple.com/documentation/messages/msconversation/2909036-sendmessage
        */
        Task {
            conversation.send(message)
        }
    }
    
    func createToDoList(list: ToDoList){
        guard let conversation = activeConversation else { fatalError("Expected a conversation") }
        guard let message = self.composeMessage(list: list) else { return }
        conversation.send(message) { error in
            if let error = error {
                print(error)
            }
        }
                
        dismiss()
    }
    
    private func composeMessage(list: ToDoList, session: MSSession? = nil) -> MSMessage? {
        if list.name.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
            // set the app name for the list if no name is set
            list.name = Bundle.main.localizedInfoDictionary!["CFBundleDisplayName"] as! String
        }
        
        let message = MSMessage(session: session ?? MSSession())
        message.summaryText = list.name
        
        // define the layouts for the message
        let alternateMessageLayout = MSMessageTemplateLayout()
        alternateMessageLayout.caption = list.name
        alternateMessageLayout.subcaption = NSLocalizedString("GetExtension", comment: "")
        alternateMessageLayout.image = UIImage(named: "MessagePreviewImage")
        
        let layout = MSMessageLiveLayout(alternateLayout: alternateMessageLayout)
        message.layout = layout
        
        guard let conversation = activeConversation else { fatalError("Expected a conversation") }
        
        let author = conversation.localParticipantIdentifier
        list.setAuthor(name: author.uuidString)
        message.url = list.getUrl()
        
        return message
    }
    
    /* renders the message when the style changes
        or it becomes active or whenever it needs
        to be rendered */
    private func renderMessage(conversation: MSConversation, message: MSMessage? = nil) async {
        print("renderMessage(): presentationStyle = " + String(presentationStyle.rawValue))
        
        if presentationStyle == .transcript {
            let curMessage = message ?? conversation.selectedMessage
            if curMessage != nil {
                let messageUrl = curMessage!.url
                if messageUrl != nil {
                    DispatchQueue.main.async {
                        self.messageView!.parseListFromURL(url: messageUrl!)
                        self.messageView!.localUserUuid = conversation.localParticipantIdentifier.uuidString
                    }
                } else {
                    print("URL in the message is nil!")
                }
            } else {
                print("Couldn't get the selected message in renderMessage()")
            }
        }
    }
    
    
    // this method overrides the content size to manipulate the
    // size of the transcript view of this application
    override func contentSizeThatFits(_ size: CGSize) -> CGSize {
        var result: CGSize = CGSize(width: 240, height: 204)
        
        if messageView != nil  {
            let itemCount = messageView!.getItemCount()
            result.height = CGFloat(140 + (42 * (itemCount)))
            
            if messageView!.requireLargeWidth() {
                result.width = 320
            }
        }
        
        return result
    }
    
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.
        
        // Use this method to configure the extension and restore previously stored state.
        print("MSMessagesAppViewController.willBecomeActive")
        
        Task {
            await renderMessage(conversation: conversation)
        }
    }
    
    override func didBecomeActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.
        
        // Use this method to configure the extension and restore previously stored state.
        print("MSMessagesAppViewController.didBecomeActive")
        
        // this doesn't fix anything on iOS 17.1.1
        /* Task {
            await renderMessage(conversation: conversation)
        } */
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dismisses the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
        print("MSMessagesAppViewController.didResignActive")
    }
   
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
        print("MSMessagesAppViewController.didReceive")
        Task {
            await renderMessage(conversation: conversation, message: message)
        }
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
        // ATTN: also callend when immediately sending!
        print("MSMessagesAppViewController.didStartSending")
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
    
        // Use this to clean up state related to the deleted message.
        print("MSMessagesAppViewController.didCancelSending")
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
    
        // Use this method to prepare for the change in presentation style.
        print("MSMessagesAppViewController.willTransition")
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
    
        // Use this method to finalize any behaviors associated with the change in presentation style.
        print("MSMessagesAppViewController.didTransition")
    }

}
