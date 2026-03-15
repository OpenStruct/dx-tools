import SwiftUI

@Observable
class UnixPermViewModel {
    var input = "755"
    var permission: UnixPermService.Permission?
    var ownerR = true
    var ownerW = true
    var ownerX = true
    var groupR = true
    var groupW = false
    var groupX = true
    var othersR = true
    var othersW = false
    var othersX = true

    init() { parse() }

    func parse() {
        if let p = UnixPermService.fromNumeric(input) {
            permission = p
            syncCheckboxes(from: p)
        } else if let p = UnixPermService.fromSymbolic(input) {
            permission = p
            syncCheckboxes(from: p)
        }
    }

    func updateFromCheckboxes() {
        let o = (ownerR ? 4 : 0) + (ownerW ? 2 : 0) + (ownerX ? 1 : 0)
        let g = (groupR ? 4 : 0) + (groupW ? 2 : 0) + (groupX ? 1 : 0)
        let t = (othersR ? 4 : 0) + (othersW ? 2 : 0) + (othersX ? 1 : 0)
        input = "\(o)\(g)\(t)"
        permission = UnixPermService.fromNumeric(input)
    }

    func copyCommand() {
        guard let p = permission else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(p.command, forType: .string)
    }

    private func syncCheckboxes(from p: UnixPermService.Permission) {
        ownerR = p.owner.contains("r"); ownerW = p.owner.contains("w"); ownerX = p.owner.contains("x") || p.owner.contains("s")
        groupR = p.group.contains("r"); groupW = p.group.contains("w"); groupX = p.group.contains("x") || p.group.contains("s")
        othersR = p.others.contains("r"); othersW = p.others.contains("w"); othersX = p.others.contains("x") || p.others.contains("t")
    }
}
