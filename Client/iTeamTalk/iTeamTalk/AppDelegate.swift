/*
 * Copyright (c) 2005-2018, BearWare.dk
 * 
 * Contact Information:
 *
 * Bjoern D. Rasmussen
 * Kirketoften 5
 * DK-8260 Viby J
 * Denmark
 * Email: contact@bearware.dk
 * Phone: +45 20 20 54 59
 * Web: http://www.bearware.dk
 *
 * This source code is part of the TeamTalk SDK owned by
 * BearWare.dk. Use of this file, or its compiled unit, requires a
 * TeamTalk SDK License Key issued by BearWare.dk.
 *
 * The TeamTalk SDK License Agreement along with its Terms and
 * Conditions are outlined in the file License.txt included with the
 * TeamTalk SDK distribution.
 *
 */

import AVFoundation
import UIKit
import TeamTalkKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    // Static so iTeamTalkApp's @State default (a struct init expression, which
    // can't read another property off `self`/`appDelegate`) can reference it
    // directly without needing a custom init.
    static let session = TeamTalkSession()
    var session: TeamTalkSession { Self.session }

    let backgroundQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
    var backgroundRunning = false
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        session.start(licenseName: REGISTRATION_NAME, licenseKey: REGISTRATION_KEY)

        // session.start() constructs the native client, which as a side effect
        // grabs the platform audio subsystem singleton and immediately activates
        // the OS audio session (earpiece-style routing, ignoring the Speaker
        // preference) - before the user has connected to any server. Deactivate
        // it here; setupSoundDevices() activates it correctly once a connection
        // actually starts.
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        // Default values are not set in Settings bundle, so we need to load them manually
        let defaults = UserDefaults.standard
        defaults.synchronize()
        
        var bundleDefaults = [String : AnyObject]()
        
        if let settingsBundle = Bundle.main.path(forResource: "Settings", ofType: "bundle") {
            
            let path = (settingsBundle as NSString).appendingPathComponent("Root.plist")
            let settings = NSDictionary(contentsOfFile: path)
            let preferences = settings!.object(forKey: "PreferenceSpecifiers") as! NSArray

            for prefSpecification in preferences {
                if let key = (prefSpecification as AnyObject).object(forKey: "Key") {
                    if defaults.object(forKey: key as! String) == nil {
                        let defValue = (prefSpecification as AnyObject).object(forKey: "DefaultValue")
                        bundleDefaults[key as! String] = defValue as AnyObject?
//                        println("Pref: " + (key as! String) + "=" + defValue)
                    }
                }
            }
            
        }

        if !bundleDefaults.isEmpty {
            defaults.register(defaults: bundleDefaults)
            defaults.synchronize()
        }
        
        TeamTalkSession.touchLinkerSymbolsForTests()
        
        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options opt: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.absoluteString.starts(with: AppInfo.TTLINK_PREFIX) || url.isFileURL {
            NotificationCenter.default.post(name: .iTeamTalkOpenURL, object: url)
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        if session.isConnected {
            backgroundRunning = true
            backgroundQueue.async(execute: testBackgroundTask)
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        backgroundRunning = false
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        session.close()
    }

    // Forward remote control events (headset buttons) via NotificationCenter
    // so that non-UIKit code can respond to them.
    override func remoteControlReceived(with event: UIEvent?) {
        NotificationCenter.default.post(name: .iTeamTalkRemoteControl, object: event)
    }

    // VoiceOver "magic tap" (two-finger double tap) bubbles up the responder
    // chain to here when no focused element handled it. Forward it like remote
    // control events so a VoiceOver user can toggle voice transmission from
    // anywhere in the app without first finding and focusing the Talk button.
    // Only claim the gesture while connected, so its default system behavior
    // still works on the server list.
    override func accessibilityPerformMagicTap() -> Bool {
        guard session.isConnected else { return false }
        NotificationCenter.default.post(name: .iTeamTalkMagicTap, object: nil)
        return true
    }

    func testBackgroundTask() {
        if (backgroundRunning) {
            endBackgroundTask()
            Thread.sleep(forTimeInterval: 5)
            backgroundQueue.async(execute: testBackgroundTask)
            registerBackgroundTask()
        }
    }
    
    func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask (expirationHandler: {
            [unowned self] in
            self.endBackgroundTask()
        })
        assert(backgroundTask != UIBackgroundTaskIdentifier.invalid)
    }
    
    func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskIdentifier.invalid
    }
}
