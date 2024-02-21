import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var paths = NSSearchPathForDirectoriesInDomains(
        FileManager.SearchPathDirectory.documentDirectory,
        FileManager.SearchPathDomainMask.userDomainMask, true
    )

    var task: Process = .init()
    var pipe: Pipe = .init()
    var file: FileHandle

    var statusBar = NSStatusBar.system
    var statusBarItem: NSStatusItem = .init()
    var menu: NSMenu = .init()

    var statusMenuItem: NSMenuItem = .init()
    var openHomePageMenuItem: NSMenuItem = .init()
    var unsetGiteaWorkDirMenuItem: NSMenuItem = .init()
    var openLogsMenuItem: NSMenuItem = .init()
    var openDataFolderItem: NSMenuItem = .init()
    var aboutMenuItem: NSMenuItem = .init()
    var versionMenuItem: NSMenuItem = .init()
    var quitMenuItem: NSMenuItem = .init()
    var openAppIniMenuItem: NSMenuItem = .init()

    override init() {
        file = pipe.fileHandleForReading
        super.init()
        if !appExistsInApplications("Gitea") {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Gitea.app Not Found in /Applications"
                alert.informativeText = "It is recommended that the Gitea application be placed in the /Applications directory for optimal performance and accessibility !"
                alert.addButton(withTitle: "OK")
                alert.alertStyle = .warning
                alert.runModal()
            }
        }
    }

    func startGiteaServer(giteaWorkDir: String) {
        task = Process()
        pipe = Pipe()
        file = pipe.fileHandleForReading

        let type = getCPUType()

        if let path = Bundle.main.path(forResource: type == "ARM64" ? "gitea-arm64" : "gitea-amd64", ofType: "", inDirectory: "App") {
            task.launchPath = path
        }

        let environment = ProcessInfo.processInfo.environment
        var modifiedEnvironment = environment
        modifiedEnvironment["GITEA_WORK_DIR"] = giteaWorkDir
        task.environment = modifiedEnvironment

        task.arguments = ["web"]
        task.standardOutput = pipe

        task.launch()

        DispatchQueue.main.async {
            self.showAlert(title: "Gitea Server", message: "Gitea started successfully on port 3000 !")
        }
    }

    func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")

        if let window = NSApp.mainWindow {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }

    func askForGiteaWorkDir() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Enter GITEA_WORK_DIR Path"
            alert.informativeText = "Please enter the path to your GITEA_WORK_DIR to start Gitea :"
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")

            let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            inputTextField.placeholderString = "~/Gitea"
            alert.accessoryView = inputTextField

            if let window = alert.window as? NSPanel {
                window.becomesKeyOnlyIfNeeded = true
                window.level = .modalPanel
            }

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                let giteaWorkDir = inputTextField.stringValue
                UserDefaults.standard.set(giteaWorkDir, forKey: "GiteaWorkDir")
                self.setupSystemMenuItem()
                self.startGiteaServer(giteaWorkDir: giteaWorkDir)
            }
        }
    }

    func getGiteaVersion() -> String {
        let process = Process()
        let pipe = Pipe()

        let type = getCPUType()

        if let path = Bundle.main.path(forResource: type == "ARM64" ? "gitea-arm64" : "gitea-amd64", ofType: "", inDirectory: "App") {
            process.launchPath = path
        }

        process.arguments = ["-v"]
        process.standardOutput = pipe
        process.standardError = pipe

        process.launch()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let version = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            let pattern = "Gitea version (\\d+\\.\\d+\\.\\d+)"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return "Error !"
            }
            let matches = regex.matches(in: version, options: [], range: NSRange(version.startIndex..., in: version))
            if let match = matches.first,
               let range = Range(match.range(at: 1), in: version)
            {
                return String(version[range])
            }
            return "Error !"
        } else {
            return "Error !"
        }
    }

    func stopGiteaServer() {
        guard task.isRunning else { return }
        task.terminate()
    }

    @objc func openLogsDirectory(_: AnyObject) {
        if let giteaWorkDir = UserDefaults.standard.string(forKey: "GiteaWorkDir") {
            let logsPath = "\(giteaWorkDir)/log"
            NSWorkspace.shared.open(URL(fileURLWithPath: logsPath))
        } else {
            showDirectoryNotSetAlert()
        }
    }

    @objc func openDataDirectory(_: AnyObject) {
        if let giteaWorkDir = UserDefaults.standard.string(forKey: "GiteaWorkDir") {
            let dataPath = "\(giteaWorkDir)/data"
            NSWorkspace.shared.open(URL(fileURLWithPath: dataPath))
        } else {
            showDirectoryNotSetAlert()
        }
    }

    @objc func openAppIniFile(_: AnyObject) {
        if let giteaWorkDir = UserDefaults.standard.string(forKey: "GiteaWorkDir") {
            let appIniPath = "\(giteaWorkDir)/custom/conf/app.ini"
            NSWorkspace.shared.open(URL(fileURLWithPath: appIniPath))
        } else {
            showDirectoryNotSetAlert()
        }
    }

    func showDirectoryNotSetAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "GITEA_WORK_DIR Not Set"
            alert.informativeText = "The GITEA_WORK_DIR has not been set. Please set it before trying to open directories or files."
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    @objc func openHomePage(_: AnyObject) {
        if let url = URL(string: "http://localhost:3000") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func unsetGiteaWorkDir(_: AnyObject) {
        UserDefaults.standard.removeObject(forKey: "GiteaWorkDir")
        showAlertGiteaWorkDirUnset()
    }

    func showAlertGiteaWorkDirUnset() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "GITEA_WORK_DIR Unset"
            alert.informativeText = "The GITEA_WORK_DIR has been unset. But Gitea will continue to work with the current configuration. Please quit and restart it to set a new GITEA_WORK_DIR."
            alert.addButton(withTitle: "OK")

            if let window = NSApplication.shared.keyWindow {
                alert.beginSheetModal(for: window, completionHandler: nil)
            } else {
                alert.runModal()
            }
        }
    }

    func setupSystemMenuItem() {
        statusBarItem = statusBar.statusItem(withLength: -1)
        statusBarItem.menu = menu
        let icon = NSImage(named: "logo")!
        icon.isTemplate = true
        statusBarItem.image = icon

        let giteaVersion = getGiteaVersion()

        versionMenuItem.title = "Gitea"
        versionMenuItem.title = "Gitea v\(giteaVersion)"
        menu.addItem(versionMenuItem)
        statusMenuItem.title = "Running on Port 3000"
        menu.addItem(statusMenuItem)

        openHomePageMenuItem.title = "Open home page"
        openHomePageMenuItem.action = #selector(AppDelegate.openHomePage(_:))
        menu.addItem(openHomePageMenuItem)

        openDataFolderItem.title = "Open data folder"
        openDataFolderItem.action = #selector(AppDelegate.openDataDirectory(_:))
        menu.addItem(openDataFolderItem)

        openAppIniMenuItem.title = "Open app.ini File"
        openAppIniMenuItem.action = #selector(AppDelegate.openAppIniFile(_:))
        menu.addItem(openAppIniMenuItem)

        openLogsMenuItem.title = "Open logs folder"
        openLogsMenuItem.action = #selector(AppDelegate.openLogsDirectory(_:))
        menu.addItem(openLogsMenuItem)

        unsetGiteaWorkDirMenuItem.title = "Unset GITEA_WORK_DIR"
        unsetGiteaWorkDirMenuItem.action = #selector(AppDelegate.unsetGiteaWorkDir(_:))
        menu.addItem(unsetGiteaWorkDirMenuItem)

        aboutMenuItem.title = "About"
        aboutMenuItem.action = #selector(NSApplication.orderFrontStandardAboutPanel(_:))
        menu.addItem(aboutMenuItem)

        quitMenuItem.title = "Quit"
        quitMenuItem.action = #selector(NSApplication.shared.terminate)
        menu.addItem(quitMenuItem)
    }

    func getCPUType() -> String {
        var size = 0
        sysctlbyname("hw.cputype", nil, &size, nil, 0)

        var cpuType: cpu_type_t = 0
        sysctlbyname("hw.cputype", &cpuType, &size, nil, 0)

        switch cpuType {
        case CPU_TYPE_X86_64:
            return "X86_64"
        case CPU_TYPE_ARM64:
            return "ARM64"
        default:
            return "UNKNOWN"
        }
    }

    func appExistsInApplications(_ appName: String) -> Bool {
        let found = [
            "/Applications/\(appName).app",
            "/Applications/Utilities/\(appName).app",
            "\(NSHomeDirectory())/Applications/\(appName).app",
        ].map {
            FileManager.default.fileExists(atPath: $0)
        }.reduce(false) {
            if $0 == false && $1 == false {
                return false
            } else {
                return true
            }
        }

        return found
    }

    func applicationDidFinishLaunching(_: Notification) {
        if UserDefaults.standard.string(forKey: "GiteaWorkDir") == nil {
            askForGiteaWorkDir()
        } else {
            let giteaWorkDir = UserDefaults.standard.string(forKey: "GiteaWorkDir")!
            setupSystemMenuItem()
            startGiteaServer(giteaWorkDir: giteaWorkDir)
        }
    }

    func applicationWillTerminate(_: Notification) {
        stopGiteaServer()
    }
}
