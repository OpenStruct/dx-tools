import SwiftUI

struct EnvSwitcherView: View {
    @State private var vm = EnvSwitcherViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "Env Switcher", icon: "arrow.triangle.swap") {
                Spacer()
                DXButton(title: "Browse", icon: "folder", style: .secondary) { vm.browseForProject() }
                DXButton(title: "Add Project", icon: "plus") {
                    vm.showAddProject = true
                }
            }

            HSplitView {
                // Left — Project list
                VStack(spacing: 0) {
                    EditorPaneHeader(title: "PROJECTS", icon: "folder") {}
                    Rectangle().fill(t.border).frame(height: 1)
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 4) {
                            ForEach(Array(vm.projects.enumerated()), id: \.element.id) { i, project in
                                projectRow(project, index: i)
                            }
                            if vm.projects.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "folder.badge.plus")
                                        .font(.system(size: 28, weight: .ultraLight))
                                        .foregroundStyle(t.textGhost)
                                    Text("Add a project to get started")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(t.textGhost)
                                }
                                .padding(.top, 40)
                            }
                        }
                        .padding(8)
                    }
                }
                .background(t.bgSecondary)
                .frame(minWidth: 180, maxWidth: 220)

                // Right — Profiles + preview
                VStack(spacing: 0) {
                    if let project = vm.selectedProject {
                        // Profile cards
                        VStack(spacing: 0) {
                            HStack {
                                EditorPaneHeader(title: "\(project.name.uppercased()) PROFILES", icon: "square.stack") {}
                                Spacer()
                                SmallIconButton(title: "Import .env", icon: "square.and.arrow.down") {
                                    vm.importCurrentAsProfile()
                                    if let action = vm.lastAction { appState.showToast(action, icon: "checkmark") }
                                }
                                SmallIconButton(title: "New", icon: "plus") { vm.showAddProfile = true }
                            }
                            .padding(.trailing, 8)
                            Rectangle().fill(t.border).frame(height: 1)

                            ScrollView(showsIndicators: false) {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 10)], spacing: 10) {
                                    ForEach(project.profiles) { profile in
                                        profileCard(profile, isActive: project.activeProfileId == profile.id)
                                    }
                                }
                                .padding(12)
                            }
                            .frame(minHeight: 120, maxHeight: 200)
                        }

                        Rectangle().fill(t.border).frame(height: 1)

                        // Preview
                        VStack(spacing: 0) {
                            HStack {
                                EditorPaneHeader(title: "CURRENT \(project.envFileName.uppercased())", icon: "doc.text") {}
                                Spacer()
                            }
                            .padding(.trailing, 8)
                            Rectangle().fill(t.border).frame(height: 1)
                            CodeEditor(text: .constant(vm.previewContent), isEditable: false, language: "plain")
                        }
                    } else {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "arrow.triangle.swap")
                                .font(.system(size: 36, weight: .ultraLight))
                                .foregroundStyle(t.textGhost)
                            Text("Select a project")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(t.textTertiary)
                            Text("Add a project folder to manage its environment profiles")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(t.textGhost)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .background(t.editorBg)
                .frame(minWidth: 400)
            }
        }
        .background(t.bg)
        .onAppear { vm.loadProjects() }
        .sheet(isPresented: $vm.showAddProject) { addProjectSheet }
        .sheet(isPresented: $vm.showAddProfile) { addProfileSheet }
    }

    // MARK: - Components

    func projectRow(_ project: EnvSwitcherService.Project, index: Int) -> some View {
        let isSelected = vm.selectedProjectIndex == index
        return HStack(spacing: 8) {
            Circle()
                .fill(project.activeProfileId != nil ? t.success : t.textGhost.opacity(0.3))
                .frame(width: 7, height: 7)
            VStack(alignment: .leading, spacing: 1) {
                Text(project.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? t.accent : t.text)
                Text("\(project.profiles.count) profiles")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(t.textGhost)
            }
            Spacer()
            Button { vm.removeProject(at: index) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(t.textGhost)
            }
            .buttonStyle(.plain)
            .opacity(isSelected ? 1 : 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelected ? t.accent.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .contentShape(Rectangle())
        .onTapGesture {
            vm.selectedProjectIndex = index
            vm.loadPreview()
        }
    }

    func profileCard(_ profile: EnvSwitcherService.EnvProfile, isActive: Bool) -> some View {
        let color = Color(hex: profile.color)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(profile.name)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(t.text)
                Spacer()
                if isActive {
                    Text("ACTIVE")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundStyle(t.success)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(t.success.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            Text("\(profile.variables) variables")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(t.textTertiary)
            HStack(spacing: 4) {
                if !isActive {
                    Button {
                        vm.switchTo(profile)
                        if let action = vm.lastAction { appState.showToast(action, icon: "checkmark.circle") }
                    } label: {
                        Text("Switch →")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundStyle(t.accent)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Button { vm.deleteProfile(profile.id) } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 9))
                        .foregroundStyle(t.error)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(t.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isActive ? color : t.border, lineWidth: isActive ? 1.5 : 0.5))
    }

    var addProjectSheet: some View {
        VStack(spacing: 16) {
            Text("Add Project")
                .font(.system(size: 16, weight: .bold, design: .rounded))
            TextField("Project Name", text: $vm.newProjectName)
                .textFieldStyle(.roundedBorder)
            HStack {
                TextField("Project Path", text: $vm.newProjectPath)
                    .textFieldStyle(.roundedBorder)
                Button("Browse") { vm.browseForProject() }
            }
            HStack {
                Button("Cancel") { vm.showAddProject = false }
                Spacer()
                Button("Add") { vm.addProject() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 400)
    }

    var addProfileSheet: some View {
        VStack(spacing: 16) {
            Text("New Profile")
                .font(.system(size: 16, weight: .bold, design: .rounded))
            TextField("Profile Name (e.g. Production)", text: $vm.newProfileName)
                .textFieldStyle(.roundedBorder)
            HStack(spacing: 8) {
                Text("Color:")
                ForEach(["#4ADE80", "#FBBF24", "#F87171", "#60A5FA", "#A78BFA"], id: \.self) { hex in
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(vm.newProfileColor == hex ? Color.white : Color.clear, lineWidth: 2))
                        .onTapGesture { vm.newProfileColor = hex }
                }
            }
            TextEditor(text: $vm.profileContent)
                .font(.system(size: 11, design: .monospaced))
                .frame(height: 200)
                .border(Color.gray.opacity(0.3))
            HStack {
                Button("Cancel") { vm.showAddProfile = false }
                Spacer()
                Button("Create") { vm.addProfile() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 500)
    }
}


