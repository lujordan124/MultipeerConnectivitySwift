//
//  SessionManager.swift
//  SwiftPartDownloader
//
//  Created by Jordan Lu on 7/18/14.
//  Copyright (c) 2014 jordanLu. All rights reserved.
//

import Foundation

class SessionManager : AFHTTPSessionManager
{
    class var sharedInstance: SessionManager
        {
            struct Singleton
            {
                static let instance = SessionManager()
            }
            return Singleton.instance
    }
    
    init()
    {
        let baseURLString = NSURL.URLWithString("http://localhost:9292/v1/")
        super.init(baseURL: baseURLString, sessionConfiguration: nil)
        
        self.responseSerializer = AFJSONResponseSerializer(readingOptions: (NSJSONReadingOptions.MutableLeaves | NSJSONReadingOptions.MutableContainers))
    }
    
    func checkServerForUpdates(versionNumber: String,
        success:(task: NSURLSessionDataTask!, responseObject: AnyObject!) -> (),
        failure:(task: NSURLSessionDataTask!, error: NSError!) -> (Void)) -> NSURLSessionDataTask
    {
        let params = NSMutableDictionary()
        params.setValue(versionNumber, forKey: "v")
        
        var localSuccess = { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> () in
            if task
            {
                success(task: task, responseObject: responseObject)
            }
        }
        
        var task = self.GET("version",
            parameters: params,
            success: localSuccess,
            failure: failure)
        
        return NSURLSessionDataTask()
    }
}