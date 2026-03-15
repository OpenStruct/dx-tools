import SwiftUI

struct UnixPermView: View {
    @State private var vm = UnixPermViewModel()
    @Environment(\.theme) private var t

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Input
                VStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill").font(.system(size: 10, weight: .bold)).foregroundStyle(t.accent)
                        Text("PERMISSION INPUT").font(.system(size: 9.5, weight: .heavy, design: .rounded)).foregroundStyle(t.textTertiary).tracking(0.8)
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        TextField("e.g. 755 or rwxr-xr-x", text: $vm.input)
                            .textFieldStyle(.plain)
                            .font(.system(size: 28, weight: .black, design: .monospaced))
                            .foregroundStyle(t.text)
                            .padding(16)
                            .background(t.editorBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(t.border, lineWidth: 1))
                            .onSubmit { vm.parse() }
                            .onChange(of: vm.input) { _, _ in vm.parse() }

                        if let p = vm.permission {
                            VStack(spacing: 4) {
                                Text(p.lsFormat)
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .foregroundStyle(t.accent)
                                Text(p.command)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(t.textTertiary)
                            }
                            .padding(16)
                            .background(t.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(t.border, lineWidth: 1))
                        }
                    }
                }

                // Checkbox grid
                if vm.permission != nil {
                    HStack(spacing: 16) {
                        permColumn("Owner", r: $vm.ownerR, w: $vm.ownerW, x: $vm.ownerX)
                        permColumn("Group", r: $vm.groupR, w: $vm.groupW, x: $vm.groupX)
                        permColumn("Others", r: $vm.othersR, w: $vm.othersW, x: $vm.othersX)
                    }
                    .onChange(of: vm.ownerR) { _, _ in vm.updateFromCheckboxes() }
                    .onChange(of: vm.ownerW) { _, _ in vm.updateFromCheckboxes() }
                    .onChange(of: vm.ownerX) { _, _ in vm.updateFromCheckboxes() }
                    .onChange(of: vm.groupR) { _, _ in vm.updateFromCheckboxes() }
                    .onChange(of: vm.groupW) { _, _ in vm.updateFromCheckboxes() }
                    .onChange(of: vm.groupX) { _, _ in vm.updateFromCheckboxes() }
                    .onChange(of: vm.othersR) { _, _ in vm.updateFromCheckboxes() }
                    .onChange(of: vm.othersW) { _, _ in vm.updateFromCheckboxes() }
                    .onChange(of: vm.othersX) { _, _ in vm.updateFromCheckboxes() }
                }

                // Details
                if let p = vm.permission {
                    HStack(spacing: 16) {
                        detailCard("Owner", p.ownerDesc, p.owner, t.accent)
                        detailCard("Group", p.groupDesc, p.group, t.info)
                        detailCard("Others", p.othersDesc, p.others, t.warning)
                    }
                }

                // Common permissions
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill").font(.system(size: 9, weight: .bold)).foregroundStyle(t.warning)
                        Text("COMMON PERMISSIONS").font(.system(size: 9.5, weight: .heavy, design: .rounded)).foregroundStyle(t.textTertiary).tracking(0.8)
                    }
                    ForEach(UnixPermService.commonPermissions, id: \.numeric) { perm in
                        Button { vm.input = perm.numeric; vm.parse() } label: {
                            HStack(spacing: 10) {
                                Text(perm.numeric)
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(t.accent)
                                    .frame(width: 40)
                                Text(perm.description)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(t.textSecondary)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(t.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.border, lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(24)
        }
        .background(t.bg)
        .toolbar { ToolbarItem(placement: .principal) {
            HStack(spacing: 7) {
                Image(systemName: "lock.shield").font(.system(size: 12, weight: .semibold)).foregroundStyle(t.accent)
                Text("Unix Permissions").font(.system(size: 13, weight: .bold, design: .rounded))
            }
        }}
    }

    func permColumn(_ title: String, r: Binding<Bool>, w: Binding<Bool>, x: Binding<Bool>) -> some View {
        VStack(spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                .foregroundStyle(t.textTertiary)
                .tracking(0.8)
            Toggle("Read", isOn: r).toggleStyle(.checkbox)
            Toggle("Write", isOn: w).toggleStyle(.checkbox)
            Toggle("Execute", isOn: x).toggleStyle(.checkbox)
        }
        .font(.system(size: 11, weight: .medium))
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(t.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(t.border, lineWidth: 0.5))
    }

    func detailCard(_ title: String, _ desc: String, _ symbolic: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            Text(symbolic)
                .font(.system(size: 20, weight: .black, design: .monospaced))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(t.textTertiary)
            Text(desc)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(t.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(t.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(t.border, lineWidth: 0.5))
    }
}
