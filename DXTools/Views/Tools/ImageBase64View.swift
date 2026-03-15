import SwiftUI

struct ImageBase64View: View {
    @State private var vm = ImageBase64ViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "Image Base64", icon: "photo.fill")
            // Toolbar
            HStack(spacing: 12) {
                Picker("Mode", selection: $vm.mode) {
                    ForEach(ImageBase64ViewModel.Mode.allCases, id: \.self) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 260)

                if vm.mode == .encode {
                    Picker("Format", selection: $vm.format) {
                        ForEach(ImageBase64Service.ImageFormat.allCases, id: \.self) { f in
                            Text(f.rawValue).tag(f)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }

                Spacer()

                if vm.mode == .encode {
                    DXButton(title: "Choose Image", icon: "photo") { vm.loadImage() }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(t.glass)
            Rectangle().fill(t.border).frame(height: 1)

            if vm.mode == .encode {
                encodeView
            } else {
                decodeView
            }
        }
        .background(t.bg)
    }

    var encodeView: some View {
        HSplitView {
            // Image preview
            VStack(spacing: 0) {
                EditorPaneHeader(title: "IMAGE", icon: "photo") {}
                if let img = vm.previewImage {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 300, maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
                        HStack(spacing: 12) {
                            Text(vm.fileName).font(.system(size: 10, weight: .semibold, design: .monospaced))
                            Text(vm.fileSize).font(.system(size: 10, weight: .medium)).foregroundStyle(t.textTertiary)
                        }
                        .foregroundStyle(t.textSecondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(t.editorBg)
                } else {
                    VStack(spacing: 10) {
                        Spacer()
                        Image(systemName: "photo.on.rectangle.angled").font(.system(size: 30, weight: .ultraLight)).foregroundStyle(t.textGhost)
                        Text("Choose an image file").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(t.textTertiary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(t.editorBg)
                }
            }
            .frame(minWidth: 250)

            // Base64 output
            VStack(spacing: 0) {
                HStack {
                    EditorPaneHeader(title: "BASE64", icon: "doc.text") {}
                    Spacer()
                    if !vm.base64Output.isEmpty {
                        SmallIconButton(title: "Copy Base64", icon: "doc.on.doc") {
                            vm.copyBase64()
                            appState.showToast("Base64 copied", icon: "doc.on.doc")
                        }
                        SmallIconButton(title: "Copy Data URI", icon: "link") {
                            vm.copyDataURI()
                            appState.showToast("Data URI copied", icon: "doc.on.doc")
                        }
                    }
                }
                .padding(.trailing, 8)

                ScrollView {
                    Text(vm.base64Output.isEmpty ? "Base64 output will appear here" : vm.base64Output)
                        .font(.system(size: 10.5, weight: .regular, design: .monospaced))
                        .foregroundStyle(vm.base64Output.isEmpty ? t.textGhost : t.text)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }
                .background(t.editorBg)
            }
            .frame(minWidth: 300)
        }
    }

    var decodeView: some View {
        HSplitView {
            // Base64 input
            VStack(spacing: 0) {
                EditorPaneHeader(title: "BASE64 INPUT", icon: "text.cursor") {}
                TextEditor(text: $vm.base64Input)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .background(t.editorBg)
                    .onChange(of: vm.base64Input) { _, _ in vm.decodeBase64() }
            }
            .frame(minWidth: 300)

            // Decoded image
            VStack(spacing: 0) {
                HStack {
                    EditorPaneHeader(title: "DECODED IMAGE", icon: "photo") {}
                    Spacer()
                    if vm.decodedImage != nil {
                        SmallIconButton(title: "Save", icon: "square.and.arrow.down") { vm.saveDecodedImage() }
                    }
                }
                .padding(.trailing, 8)

                if let img = vm.decodedImage {
                    VStack {
                        Spacer()
                        Image(nsImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 360, maxHeight: 360)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .black.opacity(0.2), radius: 8)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(t.editorBg)
                } else {
                    VStack(spacing: 10) {
                        Spacer()
                        Image(systemName: "photo").font(.system(size: 30, weight: .ultraLight)).foregroundStyle(t.textGhost)
                        Text("Paste base64 to decode").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(t.textTertiary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(t.editorBg)
                }
            }
            .frame(minWidth: 250)
        }
    }
}
