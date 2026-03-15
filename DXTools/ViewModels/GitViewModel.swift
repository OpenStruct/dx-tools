import SwiftUI

@Observable
class GitViewModel {
    var repoPath: String = ""
    var repoInfo: GitService.RepoInfo?
    var isLoading: Bool = false
    var errorMessage: String?

    func browse() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a Git repository folder"
        if panel.runModal() == .OK, let url = panel.url {
            repoPath = url.path
            refresh()
        }
    }

    func refresh() {
        guard !repoPath.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let info = GitService.getRepoInfo(at: repoPath)
            DispatchQueue.main.async {
                self.repoInfo = info
                self.isLoading = false
                if info == nil { self.errorMessage = "Not a git repository" }
            }
        }
    }
}
