//
//  MainListVC.swift
//  FIndAppDocument
//
//  Created by Yun on 2019/5/5.
//  Copyright © 2019 Higgs. All rights reserved.
//

import Cocoa
import Foundation

struct CSimulator {
    var sys:String!//模拟器版本 10.0
    var name:String!//模拟器名称 iPhone X
    var uuid:String!//模拟器uuid xxxxx-xxxxxx-xxxxx
}
/// 获取的app info
struct IpaInfo {
    var name:String!
    var bundleID:String!
    var ipaIcon:Data?
    var simulator:CSimulator?
    
    init() {
        
    }
}

class MainListVC: NSViewController,NSTableViewDelegate,NSTableViewDataSource {
    private var allIpas:[String] = [String]()
    private var ipasInfo:[IpaInfo] = [IpaInfo]()
    @IBOutlet var tb:NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tb.delegate = self
        tb.dataSource = self
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        getAllPS()
    }
    
    func getAllPS() {
        let paPath = Bundle.main.path(forResource: "ps", ofType: "sh") ?? ""
        runTask(launchPath: "/bin/sh", arguments: [paPath]) {
            let manager = FileManager.default
            let urlForDocument = manager.urls( for: .cachesDirectory,
                                               in:.userDomainMask)
            let url = urlForDocument[0]
            let file = url.appendingPathComponent("ps.txt")
            if let s = try? String.init(contentsOf: file){
                self.allIpas.removeAll()
                self.ipasInfo.removeAll()
                let listOUt = s.components(separatedBy: "\n")
                for item in listOUt{
                    let b1 = item.contains("/Library/Developer/CoreSimulator/Devices/")
                    let b2 = item.contains(".app")
                    if b1 && b2{
                        self.allIpas.append(item)
                    }
                }
                self.parseIpaInfo()
                self.deleteFile(fileName: "ps.txt")
            }
        }
    }

    private func openFolder(ipa:IpaInfo){
        let task = Process.init()
        let outPip = Pipe()
        task.standardOutput = outPip
        
        task.launchPath = "/usr/bin/xcrun"
        task.arguments = ["simctl","get_app_container",ipa.simulator?.uuid ?? "booted",ipa.bundleID!,"data"]
        task.launch()
        DispatchQueue.global().async {
            task.waitUntilExit()
            
            let f = outPip.fileHandleForReading.availableData
            if let str = String.init(data: f, encoding: .utf8){
                if str.count != 0{
                    let paPath = Bundle.main.path(forResource: "open", ofType: "sh") ?? ""
                    let tmpStr = try! String.init(contentsOf: URL.init(fileURLWithPath: paPath))
                    let writeSh = tmpStr.replacingOccurrences(of: "$filepath", with: str)
                    
                    let manager = FileManager.default
                    let urlForDocument = manager.urls( for: .cachesDirectory,
                                                       in:.userDomainMask)
                    let url = urlForDocument[0]
                    let file = url.appendingPathComponent("open.sh")
                    manager.createFile(atPath: file.path, contents: writeSh.data(using: .utf8), attributes: nil)
                    
                    self.runTask(launchPath: "/bin/sh", arguments: [file.path], callBack: {
                        self.deleteFile(fileName: "open.sh")
                    })
                }else{
                    DispatchQueue.main.async {
                        let alert = NSAlert.init()
                        alert.messageText = "打开失败，请关掉模拟器重新运行"
                        alert.addButton(withTitle: "确定")
                        alert.alertStyle = .warning
                        alert.runModal()
                    }
                }
            }
        }
    }
    
    
    /// 执行脚本
    ///
    /// - Parameters:
    ///   - launchPath: 路径
    ///   - arguments: 参数
    private func runTask(launchPath:String,arguments:[String],callBack:@escaping ()->()){
        let task = Process.init()
        task.launchPath = launchPath
        task.arguments = arguments
        task.launch()
        DispatchQueue.global().async {
            task.waitUntilExit()
            DispatchQueue.main.async {
                callBack()
            }
        }
    }
    
    /// 删除桌面文件
    ///
    /// - Parameter fileName: 文件名
    private func deleteFile(fileName:String){
        let manager = FileManager.default
        let urlForDocument = manager.urls( for: .cachesDirectory,
                                           in:.userDomainMask)
        let url = urlForDocument[0]
        let file = url.appendingPathComponent(fileName)
        let _ = try? manager.removeItem(at:file)
    }
    
    ///解析plist里面的文件，获取对应的参数
    private func parseIpaInfo(){
        for item in allIpas{
            var tmpArray = item.components(separatedBy: "/")
            let _ = tmpArray.removeFirst()
            let _ = tmpArray.removeLast()
            let ipaFolder = tmpArray.joined(separator: "/")
            let plistFilre = "/" + ipaFolder + "/Info.plist"
            if let dic = NSMutableDictionary.init(contentsOf: URL.init(fileURLWithPath: plistFilre)){
                var info = IpaInfo.init()
                let bundleName:String = dic["CFBundleName"] as? String ?? ""
                let bundleId:String = dic["CFBundleIdentifier"] as? String ?? ""
                info.bundleID = bundleId
                info.name = bundleName
                let icons:NSDictionary = dic["CFBundleIcons"] as? NSDictionary ?? NSDictionary()
                if icons.count > 0{
                    if let p:NSDictionary = icons["CFBundlePrimaryIcon"] as? NSDictionary{
                        let IconFiles:[String] = p["CFBundleIconFiles"] as? [String] ?? [String]()
                        let i = IconFiles.last ?? ""
                        let iconUrl = "/" + ipaFolder + "/\(i)@3x.png"
                        if let iconData = try? Data.init(contentsOf: URL.init(fileURLWithPath: iconUrl)){
                            info.ipaIcon = iconData
                        }
                    }
                }
                if let a:AppDelegate = NSApplication.shared.delegate as? AppDelegate{
                    for item in a.allSimulator{
                        if ipaFolder.contains(item.uuid){
                            info.simulator = item
                        }
                    }
                }
                
                self.ipasInfo.append(info)
                self.tb.reloadData()
            }
        }
    }
    
    fileprivate func closePanel(){
        if let a:AppDelegate = NSApplication.shared.delegate as? AppDelegate{
            a.pop.performClose(nil)
        }
    }
}




extension MainListVC{
    // MARK: - NSTableViewDelegate,NSTableViewDataSource
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 20
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.ipasInfo.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if ipasInfo.count == 0{
            return nil
        }
        
        let item = ipasInfo[row]
        var image:NSImage? = NSImage.init(named: NSImage.Name.init("airplane"))
        var text:String = ""
        var cellIdentifier: String = ""
        
        if tableColumn == tableView.tableColumns[0] {
            if let d = item.ipaIcon{
                image = NSImage.init(data: d) //item.icon
            }
            text = item.name
            cellIdentifier = "appname"
        } else if tableColumn == tableView.tableColumns[1] {
            image = nil
            if let n = item.simulator?.name,let os = item.simulator?.sys{
                text = os + " " + n
            }else{
                text = "模拟器"
            }
            cellIdentifier = "sim"
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.imageView?.image = image ?? nil
            return cell
        }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectRow = tb.selectedRow
        if selectRow < 0{
            return
        }
        openFolder(ipa: ipasInfo[selectRow])
        self.closePanel()
    }
}

