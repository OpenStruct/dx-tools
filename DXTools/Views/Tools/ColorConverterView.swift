import SwiftUI

struct ColorConverterView: View {
    @State private var vm = ColorViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "Color Converter", icon: "paintpalette.fill")
            // ── Input Bar ──
            HStack(spacing: 12) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(t.accent)

                TextField("#FF5733, rgb(255,87,51), hsl(11,100%,60%)", text: $vm.input)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(t.text)
                    .onSubmit { vm.convert() }
                    .onChange(of: vm.input) { _, _ in
                        if vm.input.count >= 4 { vm.convert() }
                    }

                if let r = vm.result {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(r.color)
                        .frame(width: 36, height: 28)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.15), lineWidth: 1))
                        .shadow(color: r.color.opacity(0.4), radius: 8, y: 2)
                }

                DXButton(title: "Convert", icon: "paintpalette.fill") { vm.convert() }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial.opacity(0.3))
            .background(t.glass)
            Rectangle().fill(t.border).frame(height: 1)

            if let error = vm.errorMessage {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(t.error)
                        Text(error).font(.system(size: 12, weight: .medium)).foregroundStyle(t.error)
                    }
                    Spacer()
                }
            } else if let result = vm.result {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // ── Large Preview ──
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(result.color)
                                .frame(height: 100)
                                .shadow(color: result.color.opacity(0.3), radius: 20, y: 8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.white.opacity(0.1), lineWidth: 1)
                                )

                            VStack(spacing: 4) {
                                Text(result.hex)
                                    .font(.system(size: 24, weight: .black, design: .monospaced))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 4)
                                Text(result.rgb)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }

                        // ── Values ──
                        HStack(spacing: 10) {
                            valueCard("HEX", result.hex, t.accent)
                            valueCard("RGB", result.rgb, t.info)
                            valueCard("HSL", result.hsl, t.success)
                        }

                        // ── Code Snippets ──
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("Code Snippets", icon: "chevron.left.forwardslash.chevron.right")

                            VStack(spacing: 3) {
                                codeRow("CSS", result.cssCode)
                                codeRow("SwiftUI", result.swiftUICode)
                                codeRow("Swift", result.swiftCode)
                                codeRow("Android", result.androidCode)
                                codeRow("Flutter", result.flutterCode)
                                codeRow("Tailwind", result.tailwindCode)
                            }
                        }

                        // ── Shades ──
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("Shades", icon: "circle.lefthalf.filled")

                            HStack(spacing: 3) {
                                ForEach(result.shades, id: \.percent) { shade in
                                    let shadeColor = Color(red: Double(shade.r)/255, green: Double(shade.g)/255, blue: Double(shade.b)/255)
                                    VStack(spacing: 4) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(shadeColor)
                                            .frame(height: 48)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(.white.opacity(0.08), lineWidth: 0.5)
                                            )
                                            .shadow(color: shadeColor.opacity(0.2), radius: 4, y: 2)
                                        Text("\(shade.percent)%")
                                            .font(.system(size: 8, weight: .bold, design: .rounded))
                                            .foregroundStyle(t.textGhost)
                                        Text(shade.hex)
                                            .font(.system(size: 7.5, weight: .medium, design: .monospaced))
                                            .foregroundStyle(t.textTertiary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .onTapGesture {
                                        vm.copyValue(shade.hex)
                                        appState.showToast("Copied \(shade.hex)", icon: "paintpalette.fill")
                                    }
                                }
                            }
                        }

                        // ── HSL Sliders ──
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("HSL Values", icon: "slider.horizontal.3")

                            VStack(spacing: 10) {
                                hslRow("H", value: result.h, max: 360, unit: "°", color: t.error)
                                hslRow("S", value: result.s, max: 100, unit: "%", color: t.accent)
                                hslRow("L", value: result.l, max: 100, unit: "%", color: t.info)
                            }
                        }
                    }
                    .padding(20)
                }
            } else {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "paintpalette")
                        .font(.system(size: 30, weight: .ultraLight))
                        .foregroundStyle(t.textGhost)
                    Text("Enter a color to convert")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(t.textTertiary)
                    Text("#HEX · rgb() · hsl()")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(t.textGhost)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(t.bg)
    }

    func valueCard(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(t.textTertiary)
                .tracking(0.8)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(t.text)
                .textSelection(.enabled)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(t.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(t.border, lineWidth: 0.5))
        .onTapGesture {
            vm.copyValue(value)
            appState.showToast("Copied \(value)", icon: "doc.on.doc")
        }
    }

    func codeRow(_ label: String, _ value: String) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .foregroundStyle(t.textTertiary)
                .frame(width: 56, alignment: .trailing)
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(t.text)
                .textSelection(.enabled)
                .lineLimit(1)
            Spacer()
            Button {
                vm.copyValue(value)
                appState.showToast("Copied", icon: "doc.on.doc")
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(t.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(t.surface)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(t.border, lineWidth: 0.5))
    }

    func hslRow(_ label: String, value: Double, max: Double, unit: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(color)
                .frame(width: 16)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(t.surface)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value / max), height: 6)
                }
            }
            .frame(height: 6)

            Text("\(Int(value))\(unit)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(t.textSecondary)
                .frame(width: 45, alignment: .trailing)
        }
    }

    func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 9, weight: .bold)).foregroundStyle(t.accent)
            Text(title.uppercased()).font(.system(size: 9.5, weight: .heavy, design: .rounded)).foregroundStyle(t.textTertiary).tracking(0.8)
        }
    }
}
