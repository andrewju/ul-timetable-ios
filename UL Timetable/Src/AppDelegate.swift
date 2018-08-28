//
//  AppDelegate.swift
//
//  Created by Andrew on 16/7/24.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let outOfDateMessage = "Your app version is out-of-date!\nPlease update to the latest version from App Store!"
    let errorMsg = "Please try again later."
    
    var remoteConfig: ULConfiguration?
    
    class func getRemoteConfig() -> ULConfiguration? {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            return appDelegate.remoteConfig
        }
        return nil
    }
    
    func request(requestURL: URL, completion: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) {
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: request as URLRequest) {(data, response, error) in
            
            guard let data = data, let _:URLResponse = response, error == nil else {
                print("error")
                completion(nil, response, error)
                return
            }
            completion(data, response, error)
        }
        
        task.resume()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {        
        let config = ULConfiguration()
        if config.loadDefaultConfigs() {
            config.fetchRemoteConfigs(TimeInterval(5)) { (status, _ ) in
                if status == .success {
                    if let miniVersion = config.getNumber(ULRemoteConfigurationKey.miniAppVersion.rawValue) {
                        // fetch system version from .plist file
                        let path = Bundle.main.path(forResource: "Info", ofType: "plist")
                        let resultDic = NSMutableDictionary(contentsOfFile: path!)! as NSMutableDictionary
                        if let sysVersion = resultDic.object(forKey: "systemVersion") as? Int {
                            if miniVersion.intValue > sysVersion {
                                DispatchQueue.main.async {
                                    let alert = UIAlertController(title: nil, message: self.outOfDateMessage, preferredStyle: UIAlertControllerStyle.alert)
                                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {(_: UIAlertAction) in Thread.sleep(forTimeInterval: 0.5); exit(0)}))
                                    self.window?.rootViewController?.present(alert, animated: true, completion: nil)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    let mainStoryBoard = UIStoryboard.init(name: "Main", bundle: nil)
                                    if let mainVC = mainStoryBoard.instantiateInitialViewController() {
                                        self.window?.rootViewController?.present(mainVC, animated: false, completion: nil)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // more error handling
                    let alert = UIAlertController(title: nil, message: self.errorMsg, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {(_: UIAlertAction) in Thread.sleep(forTimeInterval: 0.5); exit(0)}))
                    self.window?.rootViewController?.present(alert, animated: true, completion: nil)
                }
            }
            self.remoteConfig = config
        }
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
}
