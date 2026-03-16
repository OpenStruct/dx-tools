import SwiftUI

struct ScreenshotView: View {
    @State private var vm = ScreenshotViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "Screenshot", icon: "camera.viewfinder") {
                Spacer()
                DXButton(title: "Capture", icon: "camera", style: .secondary) { vm.captureFullScreen() }
                DXButton(title: "Paste", icon: "doc.on.clipboard", style: .secondary) { vm.captureFromClipboard() }
                DXButton(title: "Open", icon: "folder", style: .secondary) { vm.loadFromFile() }
                if vm.displayImage != nil {
                    DXButton(title: "Save", icon: "square.and.arrow.down", style: .secondary) { vm.save() }
                    DXButton(title: "Copy", icon: "doc.on.doc") {
                        vm.copy()
                        appState.showToast("Copied to clipboard", icon: "doc.on.doc")
                    }
                }
            }

            HSplitView {
                // Left — Tools
                VStack(spacing: 0) {
                    EditorPaneHeader(title: "TOOLS", icon: "pencil.and.outline") {}
                    Rectangle().fill(t.border).frame(height: 1)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(ScreenshotService.AnnotationType.allCases, id: \.self) { tool in
                                toolButton(tool)
                            }

                            Rectangle().fill(t.border).frame(height: 1)
                                .padding(.vertical, 4)

                            // Color swatches
                            VStack(alignment: .leading, spacing: 4) {
                                Text("COLOR")
                                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                                    .foregroundStyle(t.textGhost)
                                    .tracking(0.8)
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 24), spacing: 4)], spacing: 4) {
                                    ForEach([NSColor.red, .systemOrange, .systemBlue, .systemGreen, .white, .black], id: \.self) { color in
                                        Circle()
                                            .fill(Color(nsColor: color))
                                            .frame(width: 22, height: 22)
                                            .overlay(Circle().stroke(vm.drawingColor == color ? Color.white : Color.clear, lineWidth: 2))
                                            .overlay(Circle().stroke(t.border, lineWidth: 0.5))
                                            .onTapGesture { vm.drawingColor = color }
                                    }
                                }
                            }

                            // Line width
                            VStack(alignment: .leading, spacing: 4) {
                                Text("WIDTH: \(Int(vm.lineWidth))")
                                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                                    .foregroundStyle(t.textGhost)
                                    .tracking(0.8)
                                Slider(value: $vm.lineWidth, in: 1...8, step: 1)
                                    .controlSize(.small)
                            }

                            if vm.selectedTool == .text {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("TEXT")
                                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                                        .foregroundStyle(t.textGhost)
                                    TextField("Label", text: $vm.annotationText)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 11, design: .monospaced))
                                        .padding(6)
                                        .background(t.editorBg)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                }
                            }

                            Rectangle().fill(t.border).frame(height: 1)
                                .padding(.vertical, 4)

                            HStack(spacing: 6) {
                                Button { vm.undoAnnotation() } label: {
                                    Label("Undo", systemImage: "arrow.uturn.backward")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(t.textTertiary)

                                Button { vm.clearAnnotations() } label: {
                                    Label("Clear", systemImage: "trash")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(t.textTertiary)
                            }
                        }
                        .padding(12)
                    }
                }
                .background(t.bgSecondary)
                .frame(minWidth: 120, maxWidth: 150)

                // Center — Canvas
                VStack(spacing: 0) {
                    if let image = vm.displayImage {
                        GeometryReader { geo in
                            ScrollView([.horizontal, .vertical]) {
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                                    .background(
                                        Image(systemName: "checkerboard.rectangle")
                                            .foregroundStyle(t.textGhost.opacity(0.1))
                                    )
                                    .gesture(
                                        DragGesture()
                                            .onEnded { value in
                                                let scale = min(geo.size.width / image.size.width, geo.size.height / image.size.height)
                                                let from = CGPoint(x: value.startLocation.x / scale, y: image.size.height - value.startLocation.y / scale)
                                                let to = CGPoint(x: value.location.x / scale, y: image.size.height - value.location.y / scale)
                                                vm.addAnnotation(from: from, to: to)
                                            }
                                    )
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 48, weight: .ultraLight))
                                .foregroundStyle(t.textGhost)
                            Text("Capture or open a screenshot")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(t.textTertiary)
                            Text("Use Capture, Paste, or Open to load an image")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(t.textGhost)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // History strip
                    if !vm.history.isEmpty {
                        Rectangle().fill(t.border).frame(height: 1)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(vm.history) { ss in
                                    let thumb = ScreenshotService.thumbnail(ss.image, maxSize: 60)
                                    let selected = vm.currentScreenshot?.id == ss.id
                                    Image(nsImage: thumb)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 40)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(selected ? t.accent : t.border, lineWidth: selected ? 2 : 0.5))
                                        .onTapGesture { vm.selectFromHistory(ss) }
                                }
                            }
                            .padding(8)
                        }
                        .frame(height: 56)
                        .background(t.bgSecondary)
                    }
                }
                .background(t.editorBg)
                .frame(minWidth: 400)
            }
        }
        .background(t.bg)
    }

    func toolButton(_ tool: ScreenshotService.AnnotationType) -> some View {
        let icon: String = switch tool {
        case .arrow: "arrow.right"
        case .rectangle: "rectangle"
        case .text: "textformat"
        case .highlight: "highlighter"
        case .number: "1.circle.fill"
        }
        let selected = vm.selectedTool == tool
        return Button {
            vm.selectedTool = tool
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 18)
                Text(tool.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(selected ? t.accent : t.text)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(selected ? t.accent.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
