//
//  main.swift
//  mshare
//
//  Created by mosugi on 2021/02/02.
//

import Foundation
import Cocoa

let mShare = MShare()
let app = NSApplication.shared

app.delegate = mShare
app.run()

class MShare:NSObject,NSApplicationDelegate,NSSharingServiceDelegate{
    
    let sharingServiceName = [
        "notes": NSSharingService.Name(rawValue: "com.apple.Notes.SharingExtension"),
        "message": NSSharingService.Name.composeMessage,
        "email": NSSharingService.Name.composeEmail,
        "airdrop": NSSharingService.Name.sendViaAirDrop,
        // dont work
        // "reminders" : NSSharingService.Name(rawValue: "com.apple.reminders.RemindersShareExtension")
    ]
    
    func applicationDidFinishLaunching(_ aNotification: Notification){
        let argc = Int(CommandLine.argc)
        guard argc >= 3 else {exit(0)}
        
        let serviceName = CommandLine.arguments[1]
        let text = CommandLine.arguments[2]
        
        guard let service = sharingServiceName[serviceName]
        else{
            exit(2)
        }
        
        share(service:service,withItem: text)
    }
    
    func share(service:NSSharingService.Name,withItem:String){
        guard let sharingService: NSSharingService = NSSharingService(named: service)
        else{
            exit(2)
        }
        
        let shareItem: Any = withItem.isUrl ? NSURL(string: withItem) as Any : withItem
        
        if sharingService.canPerform(withItems: [shareItem]){
            sharingService.delegate = self
            sharingService.perform(withItems: [shareItem])
        }else{
            exit(1)
        }
        
    }
    
}

extension String {
    var isUrl: Bool {
        let linkValidation = NSTextCheckingResult.CheckingType.link.rawValue
        guard let detector = try? NSDataDetector(types: linkValidation) else { return false }
        
        let results = detector.matches(in: self, options: .reportCompletion, range: NSMakeRange(0, self.count))
        return results.first?.url != nil
    }
    
}
