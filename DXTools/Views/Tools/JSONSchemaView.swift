import SwiftUI

struct JSONSchemaView: View {
    @State private var vm = JSONSchemaViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 8) {
                if let r = vm.result {
                    HStack(spacing: 6) {
                        Image(systemName: r.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(r.isValid ? t.success : t.error)
                        Text(r.isValid ? "Valid" : "\(r.errors.count) error\(r.errors.count == 1 ? "" : "s")")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(r.isValid ? t.success : t.error)
                    }
                }
                Spacer()
                SmallIconButton(title: "Sample", icon: "doc.text") { vm.sample() }
                DXButton(title: "Validate", icon: "checkmark.shield") { vm.validate() }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(t.glass)
            Rectangle().fill(t.border).frame(height: 1)

            HSplitView {
                // JSON input
                VStack(spacing: 0) {
                    EditorPaneHeader(title: "JSON", icon: "curlybraces") {}
                    TextEditor(text: $vm.jsonInput)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .background(t.editorBg)
                }
                .frame(minWidth: 250)

                // Schema input
                VStack(spacing: 0) {
                    EditorPaneHeader(title: "SCHEMA", icon: "doc.badge.gearshape") {}
                    TextEditor(text: $vm.schemaInput)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .background(t.editorBg)
                }
                .frame(minWidth: 250)
            }

            // Errors panel
            if let r = vm.result, !r.isValid {
                Rectangle().fill(t.border).frame(height: 1)
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(r.errors, id: \.self) { error in
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(t.error)
                                Text(error)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(t.text)
                                    .textSelection(.enabled)
                                Spacer()
                            }
                            .padding(.horizontal, 12).padding(.vertical, 4)
                        }
                    }
                    .padding(8)
                }
                .frame(maxHeight: 140)
                .background(t.error.opacity(0.04))
            }
        }
        .background(t.bg)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 7) {
                    Image(systemName: "checkmark.shield.fill").font(.system(size: 12, weight: .semibold)).foregroundStyle(t.accent)
                    Text("JSON Schema Validator").font(.system(size: 13, weight: .bold, design: .rounded))
                }
            }
        }
    }
}
