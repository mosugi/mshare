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
app.setActivationPolicy(.accessory)
app.activate(ignoringOtherApps: true)
app.run()

//Thanks! https://github.com/vldmrkl/airdrop-cli
class MShare:NSObject,NSApplicationDelegate,NSSharingServiceDelegate{
        
    func applicationDidFinishLaunching(_ aNotification: Notification){

        if CommandLine.argc == 3 {
            callFromTerminal()
        } else if CommandLine.argc == 2 && CommandLine.arguments[1].hasPrefix("chrome-extension") {
            callFromChrome()
        } else {
            exit(2)
        }
        
    }
    
    func callFromTerminal() {
        
        let serviceName = CommandLine.arguments[1]
        let text = CommandLine.arguments[2]
        
        share(service:sharingService(name: serviceName),withItem: text)
    }
    
    func callFromChrome() {
        
        guard let req = chromeRead()
        else{
            exit(2)
        }
        
        let json = req.data(using: .utf8)
        let message = try! JSONDecoder().decode(ChromeExtensionMessage.self, from: json!)
        
        share(service:sharingService(name: message.service),withItem: message.text)
        
    }
    
    func sharingService(name:String) -> NSSharingService{
        
        let sharingServiceName = [
            "notes": NSSharingService.Name(rawValue: "com.apple.Notes.SharingExtension"),
            "message": NSSharingService.Name.composeMessage,
            "email": NSSharingService.Name.composeEmail,
            "airdrop": NSSharingService.Name.sendViaAirDrop,
            // dont work
            // "reminders" : NSSharingService.Name(rawValue: "com.apple.reminders.RemindersShareExtension")
        ]
        
        guard let sharingService: NSSharingService = NSSharingService(named: sharingServiceName[name]!)
        else{
            exit(2)
        }
        
        return sharingService
    }
    
    func share(service:NSSharingService,withItem:String){
        
        let shareItem: Any = withItem.isUrl ? NSURL(string: withItem) as Any : withItem
        
        if service.canPerform(withItems: [shareItem]){
            service.delegate = self
            service.perform(withItems: [shareItem])
        }else{
            exit(1)
        }
    }
    
}

struct ChromeExtensionMessage: Codable {
    let service: String
    let text: String
}

// Thanks! https://gist.github.com/tearfulDalvik/e656177d3df7521cd61dffdc24ef3ec3
func getInt(_ bytes: [UInt]) -> UInt {
    let lt = (bytes[3] << 24) & 0xff000000
    let ls = (bytes[2] << 16) & 0x00ff0000
    let lf = (bytes[1] << 8) & 0x0000ff00
    let lz = (bytes[0] << 0) & 0x000000ff
    return lt | ls | lf | lz
}

func getIntBytes(for length: Int) -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: 4)
    bytes[0] = UInt8((length & 0xFF));
    bytes[1] = UInt8(((length >> 8) & 0xFF));
    bytes[2] = UInt8(((length >> 16) & 0xFF));
    bytes[3] = UInt8(((length >> 24) & 0xFF));
    return bytes
}

func chromeRead() -> String? {
    let stdIn = FileHandle.standardInput
    var bytes = [UInt](repeating: 0, count: 4)
    guard read(stdIn.fileDescriptor, &bytes, 4) != 0 else {
        return nil
    }
    
    let len = getInt(bytes)
    return String(data: stdIn.readData(ofLength: Int(len)), encoding: .utf8)
}

func chromeWrite(_ txt: String) {
    let stdOut = FileHandle.standardOutput
    
    let len = getIntBytes(for: txt.utf8.count)
    stdOut.write(Data(bytes: len, count: 4))
    stdOut.write(txt.data(using: .utf8)!)
}

// Thanks! https://qiita.com/hcrane/items/e784a5f7c4fb5e6470e6
extension String {
    var isUrl: Bool {
        let linkValidation = NSTextCheckingResult.CheckingType.link.rawValue
        guard let detector = try? NSDataDetector(types: linkValidation) else { return false }
        
        let results = detector.matches(in: self, options: .reportCompletion, range: NSMakeRange(0, self.count))
        return results.first?.url != nil
    }
    
}
