//
//  AppDelegate.swift
//  GCM-Test
//
//  Created by 구범모 on 2015. 7. 1..
//  Copyright (c) 2015년 gbmKSquare. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GGLInstanceIDDelegate {

    var window: UIWindow?
    
    var apnsToken: NSData?
    var gcmToken: String?
    
    let topic = "/topics/global"

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Register for notification
        let categories = categoriesForInteractiveNotifications()
        let types: UIUserNotificationType = .Alert | .Sound | .Badge
        let settings = UIUserNotificationSettings(forTypes: types, categories: categories)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        
        // Start GCM service
        var configurationError: NSError?
        GGLContext.sharedInstance().configureWithError(&configurationError)
        GCMService.sharedInstance().startWithConfig(GCMConfig.defaultConfig())
        
        return true
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Connect to GCM to receive non-APNS notifications
        GCMService.sharedInstance().connectWithHandler { (error) -> Void in
            if let error = error { println("Failed to connet with error: \(error).") }
            else { self.subscribeToTopic() }
        }
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        GCMService.sharedInstance().disconnect()
    }

    // MARK: Registered for notification
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        println("Registered for remote notifications with token: \(deviceToken.description).")
        
        apnsToken = deviceToken
        
        let gcmSenderId = GGLContext.sharedInstance().configuration.gcmSenderID
        let options = [kGGLInstanceIDRegisterAPNSOption: deviceToken, kGGLInstanceIDAPNSServerTypeSandboxOption: true]
        GGLInstanceID.sharedInstance().startWithConfig(GGLInstanceIDConfig.defaultConfig())
        GGLInstanceID.sharedInstance().tokenWithAuthorizedEntity(gcmSenderId, scope: kGGLInstanceIDScopeGCM, options: options) { (gcmToken, error) -> Void in
            println("Registered for GCM with GCM token: \(gcmToken).")
            self.gcmToken = gcmToken
            self.subscribeToTopic()
        }
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        println("Failed to register for remote notifications with error: \(error).")
    }
    
    func onTokenRefresh() {
        println("Needs to request a new GCM token.")
        let gcmSenderId = GGLContext.sharedInstance().configuration.gcmSenderID
        let options = [kGGLInstanceIDRegisterAPNSOption: self.apnsToken!, kGGLInstanceIDAPNSServerTypeSandboxOption: true]
        GGLInstanceID.sharedInstance().tokenWithAuthorizedEntity(gcmSenderId, scope: kGGLInstanceIDScopeGCM, options: options) { (gcmToken, error) -> Void in
            println("Registered for GCM with renewed GCM token: \(gcmToken).")
            self.gcmToken = gcmToken
            self.subscribeToTopic()
        }
    }
    
    func subscribeToTopic() {
        /*
        GCMPubSub.sharedInstance().subscribeWithToken(gcmToken, topic: topic, options: nil) { (error) -> Void in
            if let error = error {
                if error.code ==  3001 { println("Already subscribed to topic.") }
                else { println("Failed to subscribe to topic with error: \(error).") }
            }
            else { println("Subscirbe to topic.") }
        }
        */
    }
    
    private enum NotificationAction: String {
        case Accept = "accept_id"
        case Decline = "decline_id"
        case Archive = "archive_id"
        case Delete = "delete_id"
        
        var title: String {
            switch self {
            case .Accept: return "Accept"
            case .Decline: return "Decline"
            case .Archive: return "Archive"
            case .Delete: return "Delete"
            }
        }
    }
    
    private func categoriesForInteractiveNotifications() -> Set<NSObject> {
        let acceptAction = UIMutableUserNotificationAction()
        acceptAction.identifier = NotificationAction.Accept.rawValue
        acceptAction.title = NotificationAction.Accept.title
        acceptAction.activationMode = .Background
        
        let declineAction = UIMutableUserNotificationAction()
        declineAction.identifier = NotificationAction.Decline.rawValue
        declineAction.title = NotificationAction.Decline.title
        declineAction.destructive = true
        declineAction.activationMode = .Background
        
        let invitationCategory = UIMutableUserNotificationCategory()
        invitationCategory.identifier = "invitation_id"
        invitationCategory.setActions([acceptAction, declineAction], forContext: .Default)
        invitationCategory.setActions([acceptAction, declineAction], forContext: .Minimal)
        
        let archiveAction = UIMutableUserNotificationAction()
        archiveAction.identifier = NotificationAction.Archive.rawValue
        archiveAction.title = NotificationAction.Archive.title
        archiveAction.activationMode = .Background
        
        let deleteAction = UIMutableUserNotificationAction()
        deleteAction.identifier = NotificationAction.Delete.rawValue
        deleteAction.title = NotificationAction.Delete.title
        deleteAction.destructive = true
        deleteAction.activationMode = .Foreground
        
        let managementCategory = UIMutableUserNotificationCategory()
        managementCategory.identifier = "mangement_id"
        managementCategory.setActions([archiveAction, deleteAction], forContext: .Default)
        managementCategory.setActions([archiveAction, deleteAction], forContext: .Minimal)
        
        var categories = Set<NSObject>()
        categories.insert(invitationCategory)
        categories.insert(managementCategory)
        return categories
    }
    
    // MARK: Received notifications
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        println("Received a remote notifications: \(userInfo)")
        GCMService.sharedInstance().appDidReceiveMessage(userInfo)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        println("Received a remote notification with completion handler: \(userInfo)")
        GCMService.sharedInstance().appDidReceiveMessage(userInfo)
        completionHandler(.NoData)
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        println("Received a remote notification with action: \(userInfo)")
        GCMService.sharedInstance().appDidReceiveMessage(userInfo)
        
        // Handle action
        if let identifier = identifier {
            if let action = NotificationAction(rawValue: identifier) {
                println("Handling action \(action.title).")
                switch action {
                case .Accept: break
                case .Decline: break
                case .Archive: break
                case .Delete: break
                default: break
                }
            }
        }
    }
}

