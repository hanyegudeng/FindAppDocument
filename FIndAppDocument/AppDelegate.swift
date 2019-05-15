//
//  AppDelegate.swift
//  FIndAppDocument
//
//  Created by Yun on 2019/5/5.
//  Copyright © 2019 Higgs. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let pop = PopView.init()
    var allSimulator:[CSimulator] = [CSimulator]()


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let img = NSImage.init(named: NSImage.Name.init("airplane"))
        item.button?.image = img
        item.button?.target = self
        item.button?.action = #selector(click)
        getAllSimulator()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @objc func click(){
        print("Click")
        pop.behavior = .transient
        pop.appearance = NSAppearance.init(named: NSAppearance.Name.accessibilityHighContrastVibrantLight)
        let mainList = MainListVC.init()
        pop.contentViewController = mainList
        pop.show(relativeTo: item.button!.bounds, of: item.button!, preferredEdge: .maxY)
    }
    
    
    /// 获取所有的模拟器
    func getAllSimulator(){
        let task = Process.init()
        let outPip = Pipe()
        task.standardOutput = outPip
        
        task.launchPath = "/usr/bin/xcrun"
        task.arguments = ["simctl","list","devices"]
        task.launch()
        DispatchQueue.global().async {
            task.waitUntilExit()
            let f = outPip.fileHandleForReading.availableData
            if let str = String.init(data: f, encoding: .utf8){
                let items:[String] = str.components(separatedBy: "\n")
                var systemOS = ""
                for item in items{
                    if item.hasPrefix("-- iOS"){//系统
                        systemOS = item.replacingOccurrences(of: "-- ", with: "").replacingOccurrences(of: " --", with: "")
                    }
                    if item.hasPrefix("    iPhone"){//设备
                        let tmpS = item.components(separatedBy: " (")
                        if tmpS.count > 1{
                            let device = tmpS.first?.replacingOccurrences(of: "    ", with: "")
                            let uuid = tmpS[1].replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: " ", with: "")
                            let s = CSimulator(sys: systemOS, name: device, uuid: uuid)
                            self.allSimulator.append(s)
                        }
                    }
                }
            }
            print(self.allSimulator)
        }
    }

}

