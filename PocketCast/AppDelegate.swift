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
class AppDelegate: NSObject, NSApplicationDelegate, WebPolicyDelegate, WebResourceLoadDelegate {

    @IBOutlet weak var webView: WebView!
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var reloadButton: NSButton!
    var loadedItems = 0

    var mediaKeyTap: SPMediaKeyTap?

    override init() {
        // Register defaults for the whitelist of apps that want to use media keys
        UserDefaults.standard.register(
            defaults: [kMediaKeyUsingBundleIdentifiersDefaultsKey : SPMediaKeyTap.defaultMediaKeyUserBundleIdentifiers()])
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let window = NSApplication.shared().windows.first!
        window.titlebarAppearsTransparent = true
        window.title = ""
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(red: 18.0/255.0, green: 18.0/255.0, blue: 19.0/255.0, alpha: 1.0) //NSColor(red: 244, green: 67, blue: 44, alpha: 1.0) //NSColor(red: CGFloat(0xf4)/CGFloat(0xff), green: CGFloat(0x43)/CGFloat(0xff), blue: CGFloat(0x36)/CGFloat(0xff), alpha: 1.0)
        
        let repFileName = "mainWindow"
        print("repfile: \(repFileName)")
        
        window.setFrameUsingName(repFileName)
        window.setFrameAutosaveName(repFileName)
        window.windowController?.shouldCascadeWindows = false
        
        window.isReleasedWhenClosed = false

        reloadButton.isHidden = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.gotNotification(_:)), name: NSNotification.Name(rawValue: "pocketEvent"), object: nil)

        webView.mainFrameURL = "https://playbeta.pocketcasts.com/web/"
        webView.policyDelegate = self
        webView.resourceLoadDelegate = self
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
    
    @IBAction func reloadButtonPressed(_ sender: Any) {
        webView.reload(sender)
    }
    
// MARK: - WebViewDelegate
    
    func webView(_ webView: WebView!, decidePolicyForNewWindowAction actionInformation: [AnyHashable: Any]!, request: URLRequest!, newFrameName frameName: String!, decisionListener listener: WebPolicyDecisionListener!) {
        NSWorkspace.shared().open(request.url!)
    }
    
    func webView(_: WebView!, resource: Any!, didFinishLoadingFrom: WebDataSource!) {
        if let url = didFinishLoadingFrom.request.url, url.absoluteString == "https://playbeta.pocketcasts.com/web/podcasts/index#/podcasts" {
            reloadButton.isHidden = false
        }
        
        //insertCSSString(into: webView) // 1
        // OR
        //insertContentsOfCSSFile(into: webView) // 2
    }
    
    func insertCSSString(into webView: WebView) {
        let cssString = ".app.dark-theme { color: #f4432c !important; } .player-controls button path { fill: #f4432c !important; } .seek-bar .tracks .knob-bar .knob { background-color: #f4432c !important; } .seek-bar .tracks .played-bar { background-color: white !important; } button.skip-forward-button.skip_forward_button { background-image: url(\"data:image/svg+xml;charset=utf-8,%3Csvg width='45' height='45' viewBox='0 0 45 45' xmlns='http://www.w3.org/2000/svg'%3E%3Ctitle%3Eplayer/skipforward%3C/title%3E%3Cpath d='M33 9H21.5C12.94 9 6 15.94 6 24.5 6 33.06 12.94 40 21.5 40 30.06 40 37 33.06 37 24.5a1 1 0 0 0-2 0C35 31.956 28.956 38 21.5 38S8 31.956 8 24.5 14.044 11 21.5 11H33v4l6-5-6-5v4z' fill='#f4432c' fill-rule='evenodd'/%3E%3C/svg%3E\"); } button.skip-back-button.skip_back_button { background-image: url(\"data:image/svg+xml;charset=utf-8,%3Csvg width='45' height='45' viewBox='0 0 45 45' xmlns='http://www.w3.org/2000/svg'%3E%3Ctitle%3Eplayer/skipback%3C/title%3E%3Cpath d='M12 9h11.5C32.06 9 39 15.94 39 24.5 39 33.06 32.06 40 23.5 40 14.94 40 8 33.06 8 24.5a1 1 0 0 1 2 0C10 31.956 16.044 38 23.5 38S37 31.956 37 24.5 30.956 11 23.5 11H12v4l-6-5 6-5v4z' fill='#f4432c' fill-rule='evenodd'/%3E%3C/svg%3E\"); } .skip-back-button p { color: #f4432c !important; } .skip-forward-button p { color: #f4432c !important; }"
        let jsString = "var style = document.createElement('style'); style.innerHTML = '\(cssString)'; document.head.appendChild(style);"
        webView.stringByEvaluatingJavaScript(from: jsString)
    }
    
    func insertContentsOfCSSFile(into webView: WebView) {
        guard let path = Bundle.main.path(forResource: "styles", ofType: "css") else { return }
        let javaScriptStr = "var link = document.createElement('link'); link.href = '\(path)'; link.rel = 'stylesheet'; document.head.appendChild(link)"
        webView.stringByEvaluatingJavaScript(from: javaScriptStr)
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
				let angularMediaPlayerSelector = "angular.element(document).injector().get('mediaPlayer')"
				
				switch(action) {
					case "playPause":
						webView.stringByEvaluatingJavaScript(
							from: "\(angularMediaPlayerSelector).playPause()")
					
					case "skipForward":
						webView.stringByEvaluatingJavaScript(
							from: "\(angularMediaPlayerSelector).jumpForward()")
					
					case "skipBack":
						webView.stringByEvaluatingJavaScript(
							from: "\(angularMediaPlayerSelector).jumpBack()")
					
					default:
						break
				}
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
