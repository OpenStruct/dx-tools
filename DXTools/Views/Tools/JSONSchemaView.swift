import SwiftUI

struct JSONSchemaView: View {
    @State private var vm = JSONSchemaViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "JSON Schema Validator", icon: "checkmark.shield.fill") {
                if let r = vm.result {
                    HStack(spacing: 6) {
                        Image(systemName: r.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(r.isValid ? t.success : t.error)
                        Text(r.isValid ? "Valid" : "\(r.errors.count) error\(r.errors.count == 1 ? "" : "s")")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(r.isValid ? t.success : t.error)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background((r.isValid ? t.success : t.error).opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                Spacer()
                SmallIconButton(title: "Sample", icon: "doc.text") { vm.sample() }
                DXButton(title: "Validate", icon: "checkmark.shield") { vm.validate() }
            }

            HSplitView {
                // JSON input
                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        EditorPaneHeader(title: "JSON DATA", icon: "curlybraces") {}
                        Spacer()
                    }
                    .padding(.trailing, 8)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $vm.jsonInput)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .background(t.editorBg)

                        if vm.jsonInput.isEmpty {
                            Text("Paste your JSON here…\n\n{\n  \"name\": \"Alice\",\n  \"age\": 30\n}")
                                .font(.system(size: 13, weight: .regular, design: .monospaced))
                                .foregroundStyle(t.textGhost)
                                .padding(.horizontal, 5).padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .frame(minWidth: 250)

                // Schema input
                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        EditorPaneHeader(title: "JSON SCHEMA", icon: "doc.badge.gearshape") {}
                        Spacer()
                    }
                    .padding(.trailing, 8)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $vm.schemaInput)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .background(t.editorBg)

                        if vm.schemaInput.isEmpty {
                            Text("Paste your schema here…\n\n{\n  \"type\": \"object\",\n  \"required\": [\"name\"],\n  \"properties\": {\n    \"name\": { \"type\": \"string\" }\n  }\n}")
                                .font(.system(size: 13, weight: .regular, design: .monospaced))
                                .foregroundStyle(t.textGhost)
                                .padding(.horizontal, 5).padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .frame(minWidth: 250)
            }

            // Results panel
            if let r = vm.result {
                Rectangle().fill(t.border).frame(height: 1)

                if r.isValid {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(t.success)
                        Text("JSON is valid against the schema")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(t.success)
                        Spacer()
                    }
                    .padding(14)
                    .background(t.success.opacity(0.04))
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(r.errors, id: \.self) { error in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(t.error)
                                        .padding(.top, 2)
                                    Text(error)
                                        .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                                        .foregroundStyle(t.text)
                                        .textSelection(.enabled)
                                    Spacer()
                                }
                                .padding(.horizontal, 12).padding(.vertical, 5)
                            }
                        }
                        .padding(6)
                    }
                    .frame(maxHeight: 160)
                    .background(t.error.opacity(0.04))
                }
            }
        }
        .background(t.bg)
        .onChange(of: vm.jsonInput) { _, _ in vm.autoValidate() }
        .onChange(of: vm.schemaInput) { _, _ in vm.autoValidate() }
    }
}
