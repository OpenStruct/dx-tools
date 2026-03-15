import SwiftUI

@Observable
class DockerViewModel {
    var containers: [DockerService.Container] = []
    var showAll: Bool = true
    var searchQuery: String = ""
    var selectedContainer: DockerService.Container?
    var logs: String = ""
    var isDockerAvailable: Bool = false
    var isLoading: Bool = false

    var filtered: [DockerService.Container] {
        if searchQuery.isEmpty { return containers }
        let q = searchQuery.lowercased()
        return containers.filter {
            $0.name.lowercased().contains(q) ||
            $0.image.lowercased().contains(q) ||
            $0.id.lowercased().contains(q)
        }
    }

    func refresh() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let available = DockerService.isDockerRunning()
            let list = available ? DockerService.listContainers(all: showAll) : []
            DispatchQueue.main.async {
                self.isDockerAvailable = available
                self.containers = list
                self.isLoading = false
            }
        }
    }

    func start(_ c: DockerService.Container) {
        DispatchQueue.global().async {
            _ = DockerService.start(c.id)
            DispatchQueue.main.async { self.refresh() }
        }
    }

    func stop(_ c: DockerService.Container) {
        DispatchQueue.global().async {
            _ = DockerService.stop(c.id)
            DispatchQueue.main.async { self.refresh() }
        }
    }

    func restart(_ c: DockerService.Container) {
        DispatchQueue.global().async {
            _ = DockerService.restart(c.id)
            DispatchQueue.main.async { self.refresh() }
        }
    }

    func remove(_ c: DockerService.Container) {
        withAnimation { containers.removeAll { $0.id == c.id } }
        DispatchQueue.global().async {
            _ = DockerService.remove(c.id)
            DispatchQueue.main.async { self.refresh() }
        }
    }

    func loadLogs(_ c: DockerService.Container) {
        selectedContainer = c
        DispatchQueue.global().async {
            let l = DockerService.logs(c.id)
            DispatchQueue.main.async { self.logs = l }
        }
    }
}
