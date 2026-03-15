import SwiftUI

struct CronView: View {
    @State private var vm = CronViewModel()
    @Environment(\.theme) private var t

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Input
                VStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.badge.checkmark.fill").font(.system(size: 10, weight: .bold)).foregroundStyle(t.accent)
                        Text("CRON EXPRESSION").font(.system(size: 9.5, weight: .heavy, design: .rounded)).foregroundStyle(t.textTertiary).tracking(0.8)
                        Spacer()
                        SmallIconButton(title: "Copy", icon: "doc.on.doc") { vm.copyExpression() }
                    }

                    TextField("*/5 * * * *", text: $vm.expression)
                        .textFieldStyle(.plain)
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundStyle(t.text)
                        .padding(20)
                        .background(t.editorBg)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(t.border, lineWidth: 1))
                        .onSubmit { vm.parse() }
                        .onChange(of: vm.expression) { _, _ in vm.parse() }

                    // Description
                    if let result = vm.result, result.isValid {
                        HStack(spacing: 8) {
                            Image(systemName: "text.quote").foregroundStyle(t.accent)
                            Text(result.description)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(t.text)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(t.accent.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(t.accent.opacity(0.15), lineWidth: 1))
                    }

                    if let error = vm.result?.error {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(t.error)
                            Text(error).font(.system(size: 12, weight: .medium)).foregroundStyle(t.error)
                        }
                        .padding(12)
                        .background(t.error.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                if let result = vm.result, result.isValid {
                    HStack(alignment: .top, spacing: 16) {
                        // Fields breakdown
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "list.bullet").font(.system(size: 9, weight: .bold)).foregroundStyle(t.accent)
                                Text("FIELDS").font(.system(size: 9.5, weight: .heavy, design: .rounded)).foregroundStyle(t.textTertiary).tracking(0.8)
                            }

                            ForEach(Array(result.parts.enumerated()), id: \.offset) { _, part in
                                HStack(spacing: 10) {
                                    Text(part.value)
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundStyle(t.accent)
                                        .frame(width: 50, alignment: .trailing)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(part.field)
                                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                                            .foregroundStyle(t.textTertiary)
                                        Text(part.meaning)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(t.text)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(t.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.border, lineWidth: 0.5))
                            }
                        }
                        .frame(maxWidth: .infinity)

                        // Next runs
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar.badge.clock").font(.system(size: 9, weight: .bold)).foregroundStyle(t.info)
                                Text("NEXT 10 RUNS").font(.system(size: 9.5, weight: .heavy, design: .rounded)).foregroundStyle(t.textTertiary).tracking(0.8)
                            }

                            let fmt = DateFormatter()
                            ForEach(Array(result.nextRuns.enumerated()), id: \.offset) { i, date in
                                let _ = { fmt.dateFormat = "EEE, MMM d yyyy HH:mm" }()
                                HStack(spacing: 8) {
                                    Text("\(i + 1)")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(t.textGhost)
                                        .frame(width: 18)
                                    Text(fmt.string(from: date))
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundStyle(t.text)
                                    Spacer()
                                    Text(relativeTime(date))
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(t.textTertiary)
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(i == 0 ? t.accent.opacity(0.04) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                // Examples
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill").font(.system(size: 9, weight: .bold)).foregroundStyle(t.warning)
                        Text("EXAMPLES").font(.system(size: 9.5, weight: .heavy, design: .rounded)).foregroundStyle(t.textTertiary).tracking(0.8)
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 6)], spacing: 6) {
                        ForEach(CronService.examples, id: \.expression) { ex in
                            Button { vm.loadExample(ex.expression) } label: {
                                HStack(spacing: 8) {
                                    Text(ex.expression)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(t.accent)
                                        .frame(width: 100, alignment: .leading)
                                    Text(ex.description)
                                        .font(.system(size: 10.5, weight: .medium))
                                        .foregroundStyle(t.textSecondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 10).padding(.vertical, 8)
                                .background(t.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                                .overlay(RoundedRectangle(cornerRadius: 7).stroke(t.border, lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(t.bg)
        .toolbar { ToolbarItem(placement: .principal) {
            HStack(spacing: 7) {
                Image(systemName: "clock.badge.checkmark").font(.system(size: 12, weight: .semibold)).foregroundStyle(t.accent)
                Text("Cron Parser").font(.system(size: 13, weight: .bold, design: .rounded))
            }
        }}
    }

    func relativeTime(_ date: Date) -> String {
        let interval = date.timeIntervalSince(Date())
        let mins = Int(interval / 60)
        if mins < 60 { return "in \(mins)m" }
        let hours = mins / 60
        if hours < 24 { return "in \(hours)h \(mins % 60)m" }
        return "in \(hours / 24)d"
    }
}
