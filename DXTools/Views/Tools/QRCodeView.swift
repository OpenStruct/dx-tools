import SwiftUI

struct QRCodeView: View {
    @State private var vm = QRCodeViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Picker("Error Correction", selection: $vm.correctionLevel) {
                    ForEach(QRCodeService.CorrectionLevel.allCases, id: \.self) { level in
                        Text(level.label).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 360)
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
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(t.glass)
            Rectangle().fill(t.border).frame(height: 1)

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
                        VStack {
                            Spacer()
                            Image(nsImage: img)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(maxWidth: 360, maxHeight: 360)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
                                .padding(20)
                            
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
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 7) {
                    Image(systemName: "qrcode").font(.system(size: 12, weight: .semibold)).foregroundStyle(t.accent)
                    Text("QR Code Generator").font(.system(size: 13, weight: .bold, design: .rounded))
                }
            }
        }
    }
}
