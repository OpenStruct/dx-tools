import SwiftUI

struct ImageBase64View: View {
    @State private var vm = ImageBase64ViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            // Single unified header
            ToolHeader(title: "Image Base64", icon: "photo.fill") {
                ThemedPicker(
                    selection: $vm.mode,
                    options: ImageBase64ViewModel.Mode.allCases,
                    label: { $0.rawValue }
                )

                if vm.mode == .encode {
                    ThemedPicker(
                        selection: $vm.format,
                        options: ImageBase64Service.ImageFormat.allCases,
                        label: { $0.rawValue }
                    )

                    Spacer()

                    DXButton(title: "Choose Image", icon: "photo") { vm.loadImage() }
                }
            }

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
                            Text(vm.fileName)
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            Text(vm.fileSize)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(t.textTertiary)
                        }
                        .foregroundStyle(t.textSecondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(t.editorBg)
                } else {
                    emptyState("photo.on.rectangle.angled", "Choose an image file", "PNG, JPEG, GIF, BMP, TIFF")
                }
            }
            .frame(minWidth: 250)

            // Base64 output
            VStack(spacing: 0) {
                EditorPaneHeader(title: "BASE64", icon: "doc.text") {
                    if !vm.base64Output.isEmpty {
                        SmallIconButton(title: "Base64", icon: "doc.on.doc") {
                            vm.copyBase64()
                            appState.showToast("Base64 copied", icon: "doc.on.doc")
                        }
                        SmallIconButton(title: "Data URI", icon: "link") {
                            vm.copyDataURI()
                            appState.showToast("Data URI copied", icon: "doc.on.doc")
                        }
                    }
                }

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
                EditorPaneHeader(title: "DECODED IMAGE", icon: "photo") {
                    if vm.decodedImage != nil {
                        SmallIconButton(title: "Save", icon: "square.and.arrow.down") {
                            vm.saveDecodedImage()
                        }
                    }
                }

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
                    emptyState("photo", "Paste base64 to decode", "Supports raw base64 and data URIs")
                }
            }
            .frame(minWidth: 250)
        }
    }

    func emptyState(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 30, weight: .ultraLight))
                .foregroundStyle(t.textGhost)
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(t.textTertiary)
            Text(subtitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(t.textGhost)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(t.editorBg)
    }
}
