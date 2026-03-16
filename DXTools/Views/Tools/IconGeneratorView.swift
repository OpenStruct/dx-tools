import SwiftUI

struct IconGeneratorView: View {
    @State private var vm = IconGeneratorViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "Icon Generator", icon: "app.dashed") {
                HStack(spacing: 4) {
                    ForEach(IconGeneratorService.Platform.allCases, id: \.self) { platform in
                        let selected = vm.selectedPlatforms.contains(platform)
                        Button {
                            vm.togglePlatform(platform)
                        } label: {
                            Text(platform.rawValue)
                                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(selected ? .white : t.textTertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(selected ? t.accent : t.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(selected ? t.accent : t.border, lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer()
                if vm.isGenerated {
                    DXButton(title: "Export", icon: "square.and.arrow.up", style: .secondary) {
                        vm.exportToFolder()
                        appState.showToast("Icons exported", icon: "checkmark")
                    }
                }
                DXButton(title: "Generate", icon: "play.fill") { vm.generate() }
            }

            HSplitView {
                // Left — Source
                VStack(spacing: 0) {
                    EditorPaneHeader(title: "SOURCE IMAGE", icon: "photo") {}
                    Rectangle().fill(t.border).frame(height: 1)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            // Drop zone / preview
                            if let image = vm.sourceImage {
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(t.border, lineWidth: 0.5))
                                    .padding(16)
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 36, weight: .ultraLight))
                                        .foregroundStyle(t.textGhost)
                                    Text("Drop image or click to browse")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(t.textTertiary)
                                    Text("Recommended: 1024×1024 PNG")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(t.textGhost)
                                }
                                .frame(maxWidth: .infinity, minHeight: 180)
                                .background(t.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                        .foregroundStyle(t.border)
                                )
                                .padding(16)
                                .contentShape(Rectangle())
                                .onTapGesture { vm.loadImage() }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    DXButton(title: "Browse", icon: "folder", style: .secondary) { vm.loadImage() }
                                    DXButton(title: "Paste", icon: "doc.on.clipboard", style: .secondary) { vm.loadFromClipboard() }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Corner Radius: \(Int(vm.cornerRadius))%")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(t.textTertiary)
                                    Slider(value: $vm.cornerRadius, in: 0...50)
                                        .controlSize(.small)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Padding: \(Int(vm.padding))%")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(t.textTertiary)
                                    Slider(value: $vm.padding, in: 0...20)
                                        .controlSize(.small)
                                }

                                if !vm.validationWarnings.isEmpty {
                                    VStack(alignment: .leading, spacing: 3) {
                                        ForEach(vm.validationWarnings, id: \.self) { w in
                                            HStack(spacing: 4) {
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(t.warning)
                                                Text(w)
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundStyle(t.textSecondary)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .background(t.bgSecondary)
                .frame(minWidth: 240, maxWidth: 300)

                // Right — Generated
                VStack(spacing: 0) {
                    HStack {
                        EditorPaneHeader(title: "GENERATED ICONS (\(vm.generatedIcons.count))", icon: "app.dashed") {}
                        Spacer()
                        if vm.isGenerated {
                            SmallIconButton(title: "Contents.json", icon: "doc.on.doc") {
                                vm.copyContentsJSON()
                                appState.showToast("Contents.json copied", icon: "doc.on.doc")
                            }
                        }
                    }
                    .padding(.trailing, 8)
                    Rectangle().fill(t.border).frame(height: 1)

                    if !vm.isGenerated {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "app.dashed")
                                .font(.system(size: 36, weight: .ultraLight))
                                .foregroundStyle(t.textGhost)
                            Text("Load an image and generate")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(t.textTertiary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 12) {
                                ForEach(vm.generatedIcons) { icon in
                                    VStack(spacing: 4) {
                                        Image(nsImage: icon.image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: min(CGFloat(icon.size.width * icon.size.scale), 72),
                                                   height: min(CGFloat(icon.size.height * icon.size.scale), 72))
                                            .background(
                                                Image(systemName: "checkerboard.rectangle")
                                                    .foregroundStyle(t.textGhost.opacity(0.3))
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 4))
                                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(t.border, lineWidth: 0.5))
                                        Text("\(icon.size.width * icon.size.scale)px")
                                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                                            .foregroundStyle(t.textGhost)
                                        Text(icon.size.platform.rawValue)
                                            .font(.system(size: 8, weight: .medium))
                                            .foregroundStyle(t.textGhost)
                                    }
                                }
                            }
                            .padding(16)
                        }
                    }
                }
                .background(t.editorBg)
                .frame(minWidth: 400)
            }
        }
        .background(t.bg)
    }
}
