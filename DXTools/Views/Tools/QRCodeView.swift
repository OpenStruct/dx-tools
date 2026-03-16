import SwiftUI

struct QRCodeView: View {
    @State private var vm = QRCodeViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "QR Code Generator", icon: "qrcode") {
                Text("Correction")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(t.textTertiary)
                ThemedPicker(
                    selection: $vm.correctionLevel,
                    options: QRCodeService.CorrectionLevel.allCases,
                    label: { $0.rawValue }
                )
                .onChange(of: vm.correctionLevel) { _, _ in vm.generate() }

                Spacer()

                if vm.qrImage != nil {
                    SmallIconButton(title: "Copy", icon: "doc.on.doc") {
                        vm.copyImage()
                        appState.showToast("QR code copied", icon: "doc.on.doc")
                    }
                    SmallIconButton(title: "Save PNG", icon: "square.and.arrow.down") {
                        vm.saveImage()
                    }
                }
            }

            HSplitView {
                // Input
                VStack(spacing: 0) {
                    EditorPaneHeader(title: "TEXT / URL", icon: "text.cursor") {}

                    TextEditor(text: $vm.input)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .background(t.editorBg)
                        .onChange(of: vm.input) { _, _ in vm.generate() }
                }
                .frame(minWidth: 300)

                // QR Output
                VStack(spacing: 0) {
                    EditorPaneHeader(title: "QR CODE", icon: "qrcode") {}

                    if let img = vm.qrImage {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(nsImage: img)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(maxWidth: 320, maxHeight: 320)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(color: .black.opacity(0.2), radius: 12, y: 4)

                            Text("\(vm.input.count) characters")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(t.textTertiary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .background(t.editorBg)
                    } else {
                        VStack(spacing: 10) {
                            Spacer()
                            Image(systemName: "qrcode")
                                .font(.system(size: 30, weight: .ultraLight))
                                .foregroundStyle(t.textGhost)
                            Text("Enter text to generate QR code")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(t.textTertiary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .background(t.editorBg)
                    }
                }
                .frame(minWidth: 300)
            }
        }
        .background(t.bg)
    }
}
