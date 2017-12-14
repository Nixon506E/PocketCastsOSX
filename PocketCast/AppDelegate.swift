//
//  AppDelegate.swift
//  PocketCast
//
//  Created by Morten Just Petersen on 4/14/15.
//  Copyright (c) 2015 Morten Just Petersen. All rights reserved.
//  Forked by Vasil Pendavinji on 11/6/2016
//

import Cocoa
import WebKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, WKUIDelegate, WKNavigationDelegate {

    @IBOutlet weak var webView: AppWebView!
    @IBOutlet weak var window: NSWindow!
    var loadedItems = 0

    var mediaKeyTap: SPMediaKeyTap?

    override init() {
        // Register defaults for the whitelist of apps that want to use media keys
        UserDefaults.standard.register(defaults: [kMediaKeyUsingBundleIdentifiersDefaultsKey : SPMediaKeyTap.defaultMediaKeyUserBundleIdentifiers()])
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let window = NSApplication.shared().windows.first!
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        //window.backgroundColor = /*NSColor(red: 18.0/255.0, green: 18.0/255.0, blue: 19.0/255.0, alpha: 1.0) //NSColor(red: 244, green: 67, blue: 44, alpha: 1.0)*/ NSColor(red: CGFloat(0xf4)/CGFloat(0xff), green: CGFloat(0x43)/CGFloat(0xff), blue: CGFloat(0x36)/CGFloat(0xff), alpha: 1.0)
        
        let repFileName = "mainWindow"
        print("repfile: \(repFileName)")
        
        window.setFrameUsingName(repFileName)
        window.setFrameAutosaveName(repFileName)
        window.windowController?.shouldCascadeWindows = false
        
        window.isReleasedWhenClosed = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.gotNotification(_:)), name: NSNotification.Name(rawValue: "pocketEvent"), object: nil)
        
        var playURL = URL(string: "https://play.pocketcasts.com/web/")
        #if BETA
            playURL = URL(string: "https://playbeta.pocketcasts.com/web/")
        #endif
        let playRequest = URLRequest(url: playURL!)
        webView.load(playRequest)
        webView.wantsLayer = true
        
        mediaKeyTap = SPMediaKeyTap(delegate: self)
        if (SPMediaKeyTap.usesGlobalMediaKeyTap()) {
            mediaKeyTap!.startWatchingMediaKeys()
        }
    }
    
    @IBAction func newWindow(_ sender: NSMenuItem) {
        window.makeKeyAndOrderFront(sender)
    }
    
    @IBAction func reloadPage(_ sender: AnyObject) {
        webView.reload(sender)
    }
    
// MARK: - WebViewDelegate
    
    /*func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        NSWorkspace.shared().open(navigationAction.request.url!)
    }*/
    
    func webView(_ myWebView: WKWebView, didFinish navigation: WKNavigation!) {
        insertCSSString(into: webView) // 1
        // OR
        //insertContentsOfCSSFile(into: webView) // 2
    }
    
    func insertCSSString(into webView: WKWebView) {
        if let filepath = Bundle.main.path(forResource: "styles", ofType: "css") {
            do {
                let cssString = try String(contentsOfFile: filepath)
                let minifiedString = String(cssString.filter { !"\n\t\r".contains($0) }).replacingOccurrences(of: "\'", with: "\\'")
                print(minifiedString)
                let jsString = "var style = document.createElement('style'); style.innerHTML = '\(minifiedString)'; document.head.appendChild(style);"
                webView.evaluateJavaScript(jsString, completionHandler: { (_, error) in
                    if let error = error { print(error.localizedDescription as Any) }
                })
            } catch {
                // contents could not be loaded
            }
        }
    }
    
    func insertContentsOfCSSFile(into webView: WKWebView) {
        guard let path = Bundle.main.path(forResource: "styles", ofType: "css") else { return }
        let jsString = "var link = document.createElement('link'); link.href = '\(path)'; link.rel = 'stylesheet'; document.head.appendChild(link)"
        webView.evaluateJavaScript(jsString, completionHandler: { (_, error) in
            if let error = error { print(error.localizedDescription as Any) }
        })
    }
    
// MARK: - AppDelegate

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false;
    }
    
    func applicationShouldHandleReopen(_ _sender: NSApplication,
                                         hasVisibleWindows flag: Bool) -> Bool{
        window.setIsVisible(true)
        return true
    }

    func gotNotification(_ notification : Notification){
		if let userInfo = notification.userInfo as? Dictionary<String,String> {
			if let action = userInfo["action"] {
				print("Got Notification \(action)")
				
                #if BETA
                    let mediaPlayerSelector = "document.getElementsByTagName('audio')[0]"
                    
                    switch(action) {
                        case "playPause":
                            webView.evaluateJavaScript("\(mediaPlayerSelector).paused ? \(mediaPlayerSelector).play() : \(mediaPlayerSelector).pause()", completionHandler: { (_, error) in
                                if let error = error { print(error.localizedDescription as Any) }
                            })
                        
                        case "skipForward":
                            webView.evaluateJavaScript("\(mediaPlayerSelector).currentTime += 30.0", completionHandler: { (_, error) in
                                    if let error = error { print(error.localizedDescription as Any) }
                            })
                        
                        case "skipBack":
                            webView.evaluateJavaScript("\(mediaPlayerSelector).currentTime -= 15.0", completionHandler: { (_, error) in
                                    if let error = error { print(error.localizedDescription as Any) }
                            })
                        
                        default:
                            break
                    }
                #else
                    let angularMediaPlayerSelector = "angular.element(document).injector().get('mediaPlayer')"

                    switch(action) {
                    case "playPause":
                        webView.evaluateJavaScript("\(angularMediaPlayerSelector).playPause()", completionHandler: { (_, error) in
                            if let error = error { print(error.localizedDescription as Any) }
                        })
                        
                    case "skipForward":
                        webView.evaluateJavaScript("\(angularMediaPlayerSelector).jumpForward()", completionHandler: { (_, error) in
                            if let error = error { print(error.localizedDescription as Any) }
                        })
                        
                    case "skipBack":
                        webView.evaluateJavaScript("\(angularMediaPlayerSelector).jumpBack()", completionHandler: { (_, error) in
                            if let error = error { print(error.localizedDescription as Any) }
                        })
                        
                    default:
                        break
                    }
                #endif
			}
		}
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu(title: "Play Control")
        let item = NSMenuItem(title: "Play/Pause", action: #selector(AppDelegate.playPause), keyEquivalent: "P")
        menu.addItem(item)
        return menu
    }
    
    func playPause(){
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: "pocketEvent"), object:NSApp, userInfo:["action":"playPause"])
    }
    
    override func mediaKeyTap(_ mediaKeyTap : SPMediaKeyTap?, receivedMediaKeyEvent event : NSEvent) {

        let keyCode = Int((event.data1 & 0xFFFF0000) >> 16);
        let keyFlags = (event.data1 & 0x0000FFFF);
        let keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;

        if (keyIsPressed) {
            switch (keyCode) {
                case Int(NX_KEYTYPE_PLAY):
                    playPause()

                case Int(NX_KEYTYPE_FAST):
                    NotificationCenter.default.post(
                        name: Notification.Name(rawValue: "pocketEvent"), object: NSApp, userInfo:["action":"skipForward"])

                case Int(NX_KEYTYPE_REWIND):
                    NotificationCenter.default.post(
                        name: Notification.Name(rawValue: "pocketEvent"), object: NSApp, userInfo:["action":"skipBack"])

                default:
                    break
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

class AppWebView: WKWebView {
    // Allow the window to still be dragged from this button
    override func mouseDown(with mouseDownEvent: NSEvent) {
        let window = self.window!
        let startingPoint = mouseDownEvent.locationInWindow
        
        // Track events until the mouse is up (in which we interpret as a click), or a drag starts (in which we pass off to the Window Server to perform the drag)
        var shouldCallSuper = false
        
        // trackEvents won't return until after the tracking all ends
        window.trackEvents(matching: [.leftMouseDragged, .leftMouseUp], timeout:NSEventDurationForever, mode: .defaultRunLoopMode) { event, stop in
            switch event.type {
            case .leftMouseUp:
                // Stop on a mouse up; post it back into the queue and call super so it can handle it
                shouldCallSuper = true
                NSApp.postEvent(event, atStart: false)
                stop.pointee = true
                
            case .leftMouseDragged:
                // track mouse drags, and if more than a few points are moved we start a drag
                let currentPoint = event.locationInWindow
                if (fabs(currentPoint.x - startingPoint.x) >= 5 || fabs(currentPoint.y - startingPoint.y) >= 5) {
                    stop.pointee = true
                    window.performDrag(with: event)
                }
                
            default:
                break
            }
        }
        
        if (shouldCallSuper) {
            super.mouseDown(with: mouseDownEvent)
        }
    }
}
