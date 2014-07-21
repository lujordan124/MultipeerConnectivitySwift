//
//  MCManager.swift
//  SwiftPartDownloader
//
//  Created by Jordan Lu on 7/18/14.
//  Copyright (c) 2014 jordanLu. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class MCManager : NSObject, MCSessionDelegate
{
    var peerID: MCPeerID! = nil
    var session: MCSession! = nil
    var browser: MCNearbyServiceBrowser! = nil
    var advertiser: MCAdvertiserAssistant! = nil
    var nearbyAdvertiser: MCNearbyServiceAdvertiser! = nil
    var checkConnected: MCBrowserViewController! = nil
    
    class var sharedInstance: MCManager
    {
        struct Singleton
        {
            static let instance = MCManager()
        }
        return Singleton.instance
    }
    
    func setupPeerAndSessionWithDisplayName(displayName: String) {
        peerID = MCPeerID(displayName: displayName)
        session = MCSession(peer: peerID)
        session.delegate = self
    }
    
    func setupMCBrowser()
    {
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: "pdfShare")
    }
    
    func setupMCAdvertiser()
    {
        nearbyAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "pdfShare")
    }
    
    func checkConnectedDevices()
    {
        checkConnected = MCBrowserViewController(serviceType: "pdfShare", session: session)
    }
    
    func advertiseSelf(shouldAdvertise: Bool)
    {
        if shouldAdvertise
        {
            advertiser = MCAdvertiserAssistant(serviceType: "pdfShare", discoveryInfo: nil, session: session)
            advertiser.start()
        }
        else
        {
            advertiser.stop()
        }
    }
    
    override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [NSObject : AnyObject]!, context: UnsafePointer<()>)
    {
        NSNotificationCenter.defaultCenter().postNotificationName("MCReceivingProgressNotification", object: nil, userInfo: ["progress" : (object: NSProgress())])
    }
    
    //MCSessionDelegate methods
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState)
    {
        var dict = ["peerID": peerID, "state": state.toRaw()]
        
        NSNotificationCenter.defaultCenter().postNotificationName("MCDidChangeStateNotification", object: nil, userInfo: dict)
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!)
    {
        var dict = ["data": data, "peerID": peerID]
        
        NSNotificationCenter.defaultCenter().postNotificationName("MCDidReceiveDataNotification", object: nil, userInfo: dict)
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!)
    {
        
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!)
    {
        var dict = ["resourceName": resourceName, "peerID": peerID, "progress": progress]
        
        NSNotificationCenter.defaultCenter().postNotificationName("MCDidStartReceivingResourceNotification", object: nil, userInfo: dict)
        
        dispatch_async(dispatch_get_main_queue(), {
            progress.addObserver(self, forKeyPath: "fractionCompleted", options: NSKeyValueObservingOptions.New, context: nil)
            })
    }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!)
    {
        var dict = ["resourceName": resourceName, "peerID": peerID, "localURL": localURL]
        
        NSNotificationCenter.defaultCenter().postNotificationName("didFinishReceivingResourceNotification", object: nil, userInfo: dict)
    }
}