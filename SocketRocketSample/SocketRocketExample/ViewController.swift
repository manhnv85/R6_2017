//
//  ViewController.swift
//  SocketRocketExample
//
//  Created by vananh on 6/19/17.
//  Copyright © 2017 vananh. All rights reserved.
//

import UIKit
import SocketRocket

class TCMessage {
    var message: String
    var incoming: Bool
    init(withMessage message:String, incoming:Bool) {
        self.incoming = incoming
        self.message = message
    }
}

class ViewController: UITableViewController {
    var webSocket: SRWebSocket?
    var messages: [TCMessage] = []
    @IBOutlet var inputTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.inputTextView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.reconnect(NSNull.self)
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 40
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.inputTextView.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.webSocket?.close()
        self.webSocket = nil
    }
    
    
    func addMessage(message: TCMessage) {
        self.messages.append(message)
        self.tableView.insertRows(at: [NSIndexPath(row: self.messages.count - 1, section: 0) as IndexPath], with: UITableViewRowAnimation.none)
        self.tableView.scrollRectToVisible((self.tableView.tableFooterView?.frame)!, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let message:TCMessage = self.messages[indexPath.row]
        let cell:TCChatCell = tableView.dequeueReusableCell(withIdentifier: message.incoming ? "ReceivedCell" : "SentCell", for: indexPath) as! TCChatCell
        cell.nameLabel.text = message.incoming ? "Others:" : "Me:"
        cell.messageLabel.text =  message.message
        
        return cell
    }
    
    
    @IBAction func sendPing(_ sender: Any) {
        if let socket = self.webSocket {
            socket.sendPing(nil)
        }
    }
    
    @IBAction func reconnect(_ sender: Any) {
        if self.webSocket != nil {
            self.webSocket?.delegate = nil
            self.webSocket?.close()
        }
        
        self.webSocket = SRWebSocket(url: URL(string: "http://192.168.181.129:9000/chat"))
        self.webSocket?.delegate = self
        
        self.title = "Openning connection"
        self.webSocket?.open()
    }
    
}


extension ViewController: SRWebSocketDelegate {
    func webSocketDidOpen(_ webSocket: SRWebSocket!) {
        self.title = "Connected"
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {
        self.title = "Connection Failed with error "
        //NSLog(error as! String)
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {
        self.addMessage(message: TCMessage(withMessage: message as! String, incoming: true))
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        NSLog("WebSocket closed")
        self.title = "Connection closed"
        self.webSocket = nil
    }
    
    func webSocket(_ webSocket: SRWebSocket!, didReceivePong pongPayload: Data!) {
        NSLog("WebSocket received pong")
    }
}

extension ViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    
        if text.range(of: "\n")?.isEmpty == false {
            var message: String = textView.text.replacingOccurrences(of: "\n", with: "")
            message = message.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
            self.webSocket?.send(message)
            self.addMessage(message: TCMessage(withMessage: message, incoming: false))
            textView.text = nil
            return false
        }
        
        return true
    }
    
}

