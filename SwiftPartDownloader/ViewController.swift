//
//  ViewController.swift
//  SwiftPartDownloader
//
//  Created by Jordan Lu on 7/17/14.
//  Copyright (c) 2014 jordanLu. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, MCBrowserViewControllerDelegate
{
    @IBOutlet var sendFilesButton: UIButton
    
    let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
    let mcManager = MCManager.sharedInstance
    let pepsiManager = SessionManager.sharedInstance
    let versionNumber = "1.0.0"
    
    var connectedDevices = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        sendFilesButton.enabled = false
        
        mcManager.setupPeerAndSessionWithDisplayName(versionNumber)
        
        self.setupMultipeerCOnnectivity()
        
        mcManager.advertiseSelf(true)
        
        println("Document Directory: \(documentDirectory)")
        println("Current Files: \(self.getAllDocuments().description)")
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "peerDidChangeStateWithNotification:", name: "MCDidChangeStateNotification", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didStartReceivingResourceWithNotification:", name: "MCDidStartReceivingResourceNotification", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didFinishReceivingResourceWithNotification:", name: "didFinishReceivingResourceNotification", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateReceivingProgressWithNotification:", name: "MCReceivingProgressNotification", object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupMultipeerCOnnectivity()
    {
        mcManager.setupMCBrowser()
        mcManager.setupMCAdvertiser()
        mcManager.checkConnectedDevices()
        
        mcManager.browser.delegate = self
        mcManager.nearbyAdvertiser.delegate = self
        mcManager.checkConnected.delegate = self
    }
    
    @IBAction func ConnectButtonPressed(sender: AnyObject)
    {
        mcManager.browser.startBrowsingForPeers()
        mcManager.nearbyAdvertiser.startAdvertisingPeer()
        self.presentViewController(mcManager.checkConnected, animated: true, completion: nil)
    }
    
    @IBAction func checkForUpdates(sender: AnyObject)
    {
        self.getServerObject(versionNumber)
    }
    @IBAction func sendFilesToOtherDevices(sender: AnyObject) {
    }
    
    func getServerObject(verNumber : String)
    {
        pepsiManager.checkServerForUpdates(verNumber, success: { task, responseObject in
            
            dispatch_async(dispatch_get_main_queue(), {
                self.getLinks(responseObject as NSArray)
                })
            
            }, failure: { task, error in
                println("\(error.description)")
            })
    }
    
    func getLinks(results: NSArray)
    {
        var downloadLinks: NSArray! = results.objectAtIndex(0).objectForKey("links") as NSArray
        if downloadLinks.count != 0
        {
            for var i = 0; i < downloadLinks.count; i++
            {
                self.downloadFileFromServer(downloadLinks.objectAtIndex(i) as String)
            }
        }
    }
    
    func downloadFileFromServer(downloadURL: NSString)
    {
        let aRequest: NSURLRequest = NSURLRequest(URL: NSURL.URLWithString(downloadURL))
        var operation: AFHTTPRequestOperation = AFHTTPRequestOperation(request: aRequest)
        let paths = documentDirectory.stringByAppendingPathComponent("fileName")
        
        operation.outputStream = NSOutputStream.outputStreamToFileAtPath(paths, append: false)
        
        operation.setCompletionBlockWithSuccess( { operation, responseObject in
            
            println("Succesfully downloaded file to \(paths)")
            
            }, failure: { operation, error in
                
                println("Error: \(error.description)")
                
            })
        
        operation.start()
    }
    
    func sendFilesToOtherDevices()
    {
        for var i = 0; i < self.getAllDocuments().count; i++
        {
            var fileDownloadPath: String = documentDirectory.stringByAppendingPathComponent(self.getAllDocuments().objectAtIndex(i) as String)
            var resourceURL: NSURL = NSURL.fileURLWithPath(fileDownloadPath)
            
            var name: String = self.getAllDocuments().objectAtIndex(i) as String
            var peer: MCPeerID = (mcManager.session.connectedPeers as NSArray).objectAtIndex(0) as MCPeerID
            
            var error: NSError? = nil
            
            dispatch_async(dispatch_get_main_queue(), {
                
                var progress: NSProgress = self.mcManager.session.sendResourceAtURL(resourceURL, withName: name, toPeer: peer, withCompletionHandler: { error in
                    
                    if error
                    {
                        //                        progress(addObserver(self, forKeyPath: "fractionCompleted", options: NSKeyValueObservingOptions.New, context: nil))
                        println("ERROR: \(error.description)")
                    }
                    else
                    {
                        println("Successfully Sent")
                    }
                    
                    })
                
                })
        }
    }
    
    func getAllDocuments() -> NSArray
    {
        let fileManager: NSFileManager = NSFileManager.defaultManager()
        var error: NSError? = nil
        var allFiles: NSArray = fileManager.contentsOfDirectoryAtPath(documentDirectory, error: &error)
        
        if error
        {
            println("ERROR: \(error.description)")
            return []
        }
        
        return allFiles
    }
    
    
    //NSNotification methods
    func peerDidChangeStateWithNotification(notification: NSNotification)
    {
        var peerID: MCPeerID = (notification.userInfo as NSDictionary).objectForKey("peerID") as MCPeerID
        var peerDisplayName: String = peerID.displayName
        var state = (notification.userInfo as NSDictionary).objectForKey("state").integerValue
        
        if state != MCSessionState.Connecting.toRaw()
        {
            if state == MCSessionState.Connected.toRaw()
            {
                connectedDevices.addObject(peerDisplayName)
                sendFilesButton.enabled = true
            }
            else if state == MCSessionState.Connected.toRaw()
            {
                if connectedDevices.count > 0
                {
                    var indexOfPeer = self.connectedDevices.indexOfObject(peerDisplayName)
                    self.connectedDevices.removeObjectAtIndex(indexOfPeer)
                    sendFilesButton.enabled = false
                }
            }
        }
    }
    
    func didStartReceivingResourceWithNotification(notification: NSNotification)
    {
        
    }
    
    func didFinishReceivingResourceWithNotification(notification: NSNotification)
    {
        var dict = notification.userInfo as NSDictionary
        
        var localURL: NSURL = NSURL(string: (dict.objectForKey("localURL") as String))
        var resourceName: String = dict.objectForKey("resourceName") as String
        
        var destinationPath: String = documentDirectory.stringByAppendingPathComponent(resourceName)
        var destinationURL: NSURL = NSURL.fileURLWithPath(destinationPath)
        
        let fileManager = NSFileManager.defaultManager()
        var error: NSError? = nil
        fileManager.copyItemAtURL(localURL, toURL: destinationURL, error: &error)
        
        if error
        {
            println("ERROR: \(error.description)")
        }
    }
    
    func updateReceivingProgressWithNotification(notification: NSNotification)
    {
        var progress: NSProgress = (notification.userInfo as NSDictionary).objectForKey("progress") as NSProgress
        println ("\(progress.description)")
    }
    
    //MCNearbyServiceBrowserDelegate methods
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!)
    {
        println("Found peer: \(peerID.displayName)")
        sendFilesButton.enabled = true
    }
    
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!)
    {
        if connectedDevices.count == 0
        {
            sendFilesButton.enabled = false
        }
        println("Lost Peer: \(peerID.displayName)")
    }
    
    func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!)
    {
        println("Did not start browsing for peer, ERROR: \(error.description)")
    }
    
    //MCNearbyServiceAdvertiserDelegate methods
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!)
    {
        println("DidReceiveInvitationFromPeer: \(peerID.displayName)")
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!)
    {
        println("didNotStartAdvertisingPeer: \(error.description)")
    }
    
    //MCBrowserViewControllerDelegate methods
    func browserViewControllerDidFinish(browserViewController: MCBrowserViewController!)
    {
        mcManager.checkConnected.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController!)
    {
        mcManager.checkConnected.dismissViewControllerAnimated(true, completion: nil)
    }
}

