import SwiftUI

@Observable
class EnvSwitcherViewModel {
    var projects: [EnvSwitcherService.Project] = []
    var selectedProjectIndex: Int?
    var showAddProject: Bool = false
    var showAddProfile: Bool = false
    var newProjectName: String = ""
    var newProjectPath: String = ""
    var newProfileName: String = ""
    var newProfileColor: String = "#4ADE80"
    var profileContent: String = ""
    var previewContent: String = ""
    var error: String?
    var lastAction: String?
    var selectedProfileId: UUID?
    var diffA: UUID?
    var diffB: UUID?
    var diffResult: [(key: String, inA: String?, inB: String?)] = []

    var selectedProject: EnvSwitcherService.Project? {
        guard let idx = selectedProjectIndex, projects.indices.contains(idx) else { return nil }
        return projects[idx]
    }

    func loadProjects() {
        projects = EnvSwitcherService.loadProjects()
    }

    func addProject() {
        let name = newProjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        let path = newProjectPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !path.isEmpty else { return }
        let envFile = EnvSwitcherService.detectEnvFile(in: path) ?? ".env"
        let project = EnvSwitcherService.Project(name: name, path: path, envFileName: envFile)
        projects.append(project)
        save()
        newProjectName = ""
        newProjectPath = ""
        showAddProject = false
        selectedProjectIndex = projects.count - 1
    }

    func removeProject(at index: Int) {
        guard projects.indices.contains(index) else { return }
        projects.remove(at: index)
        selectedProjectIndex = nil
        save()
    }

    func browseForProject() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            newProjectPath = url.path
            if newProjectName.isEmpty {
                newProjectName = url.lastPathComponent
            }
        }
    }

    func addProfile() {
        guard var project = selectedProject, let idx = selectedProjectIndex else { return }
        let name = newProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let profile = EnvSwitcherService.createProfile(name: name, color: newProfileColor, content: profileContent)
        projects[idx].profiles.append(profile)
        save()
        newProfileName = ""
        profileContent = ""
        showAddProfile = false
    }

    func importCurrentAsProfile() {
        guard let project = selectedProject, let idx = selectedProjectIndex else { return }
        guard let content = EnvSwitcherService.readEnvFile(at: project.path, fileName: project.envFileName) else {
            error = "Could not read \(project.envFileName)"
            return
        }
        let profile = EnvSwitcherService.createProfile(name: "Imported \(Date().formatted(.dateTime.month().day().hour().minute()))", color: "#60A5FA", content: content)
        projects[idx].profiles.append(profile)
        save()
        lastAction = "Imported current \(project.envFileName)"
    }

    func switchTo(_ profile: EnvSwitcherService.EnvProfile) {
        guard let project = selectedProject, let idx = selectedProjectIndex else { return }
        if EnvSwitcherService.writeEnvFile(at: project.path, fileName: project.envFileName, content: profile.content) {
            projects[idx].activeProfileId = profile.id
            projects[idx].lastSwitched = Date()
            if let pIdx = projects[idx].profiles.firstIndex(where: { $0.id == profile.id }) {
                projects[idx].profiles[pIdx].lastUsed = Date()
            }
            save()
            lastAction = "Switched to \(profile.name)"
            loadPreview()
        } else {
            error = "Failed to write \(project.envFileName)"
        }
    }

    func deleteProfile(_ id: UUID) {
        guard let idx = selectedProjectIndex else { return }
        projects[idx].profiles.removeAll { $0.id == id }
        save()
    }

    func loadPreview() {
        guard let project = selectedProject else { previewContent = ""; return }
        previewContent = EnvSwitcherService.readEnvFile(at: project.path, fileName: project.envFileName) ?? "No \(project.envFileName) found"
    }

    func computeDiff() {
        guard let project = selectedProject else { return }
        guard let a = project.profiles.first(where: { $0.id == diffA }),
              let b = project.profiles.first(where: { $0.id == diffB }) else { return }
        diffResult = EnvSwitcherService.diffProfiles(a, b)
    }

    private func save() {
        EnvSwitcherService.saveProjects(projects)
    }
}
