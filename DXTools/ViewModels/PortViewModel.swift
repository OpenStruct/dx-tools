import SwiftUI

@Observable
class PortViewModel {
    var processes: [PortProcess] = []
    var isLoading = false
    var searchQuery = ""
    var showListeningOnly = true
    var selectedProcess: PortProcess?
    var killConfirmation: PortProcess?
    var statusMessage: String?
    var statusIsError = false
    var checkPort = ""
    var checkResult: String?
    var sortBy: SortOption = .port
    var sortAscending = true

    enum SortOption: String, CaseIterable {
        case port = "Port"
        case process = "Process"
        case pid = "PID"
        case user = "User"
    }

    var filteredProcesses: [PortProcess] {
        var result = processes

        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            result = result.filter {
                "\($0.port)".contains(q) ||
                $0.processName.lowercased().contains(q) ||
                $0.command.lowercased().contains(q) ||
                $0.user.lowercased().contains(q) ||
                "\($0.pid)".contains(q)
            }
        }

        // Sort
        switch sortBy {
        case .port: result.sort { sortAscending ? $0.port < $1.port : $0.port > $1.port }
        case .process: result.sort { sortAscending ? $0.processName < $1.processName : $0.processName > $1.processName }
        case .pid: result.sort { sortAscending ? $0.pid < $1.pid : $0.pid > $1.pid }
        case .user: result.sort { sortAscending ? $0.user < $1.user : $0.user > $1.user }
        }

        return result
    }

    var portStats: (total: Int, dev: Int, db: Int, system: Int) {
        let total = processes.count
        let dev = processes.filter { $0.portCategory == .dev }.count
        let db = processes.filter { $0.portCategory == .database }.count
        let sys = processes.filter { $0.portCategory == .system }.count
        return (total, dev, db, sys)
    }

    func refresh() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let result = showListeningOnly ? PortService.listPorts() : PortService.listAllPorts()
            DispatchQueue.main.async {
                self.processes = result
                self.isLoading = false
            }
        }
    }

    func killProcess(_ proc: PortProcess) {
        // Immediately remove from UI
        withAnimation(.easeOut(duration: 0.25)) {
            processes.removeAll { $0.pid == proc.pid && $0.port == proc.port }
            if selectedProcess == proc { selectedProcess = nil }
        }

        // Kill in background
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let result = PortService.killPID(proc.pid)
            DispatchQueue.main.async {
                switch result {
                case .success(let msg):
                    self.statusMessage = "✓ \(msg) — port \(proc.port) freed"
                    self.statusIsError = false
                case .failure(let err):
                    self.statusMessage = err.localizedDescription
                    self.statusIsError = true
                    // Kill failed — add it back
                    self.processes.append(proc)
                    self.processes.sort { $0.port < $1.port }
                }
                // Sync with reality after a beat
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.refresh() }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.statusMessage = nil }
            }
        }
    }

    func killPort() {
        guard let port = Int(checkPort) else {
            statusMessage = "Enter a valid port number"
            statusIsError = true
            return
        }

        // Immediately remove matching processes from UI
        let matching = processes.filter { $0.port == port }
        guard !matching.isEmpty else {
            statusMessage = "No process found on port \(port)"
            statusIsError = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.statusMessage = nil }
            return
        }

        withAnimation(.easeOut(duration: 0.25)) {
            processes.removeAll { $0.port == port }
            if let sel = selectedProcess, sel.port == port { selectedProcess = nil }
        }

        // Kill in background
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let result = PortService.killPort(port)
            DispatchQueue.main.async {
                switch result {
                case .success(let msg):
                    self.statusMessage = "✓ \(msg)"
                    self.statusIsError = false
                    self.checkResult = "Port \(port) is available ✓"
                case .failure(let err):
                    self.statusMessage = err.localizedDescription
                    self.statusIsError = true
                    // Restore if failed
                    self.processes.append(contentsOf: matching)
                    self.processes.sort { $0.port < $1.port }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.refresh() }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.statusMessage = nil }
            }
        }
    }

    func checkPortStatus() {
        guard let port = Int(checkPort) else {
            checkResult = "Enter a valid port number"
            return
        }
        if PortService.isPortInUse(port) {
            let procs = processes.filter { $0.port == port }
            if let p = procs.first {
                checkResult = "Port \(port) is in use by \(p.processName) (PID \(p.pid))"
            } else {
                checkResult = "Port \(port) is in use"
            }
        } else {
            checkResult = "Port \(port) is available ✓"
        }
    }

    func copyProcessInfo(_ proc: PortProcess) {
        let info = """
        Port: \(proc.port)
        PID: \(proc.pid)
        Process: \(proc.processName)
        User: \(proc.user)
        Command: \(proc.command)
        """
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(info, forType: .string)
    }
}
