import SwiftUI

struct NetworkView: View {
    @State private var vm = NetworkViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "Network Info", icon: "wifi")
        ScrollView {
            VStack(spacing: 20) {
                // Network info section
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "wifi").font(.system(size: 10, weight: .bold)).foregroundStyle(t.accent)
                        Text("NETWORK INFO").font(.system(size: 9.5, weight: .heavy, design: .rounded)).foregroundStyle(t.textTertiary).tracking(0.8)
                        Spacer()
                        DXButton(title: "Refresh", icon: "arrow.clockwise", style: .secondary) { vm.loadNetworkInfo() }
                    }

                    if vm.isLoading {
                        HStack { Spacer(); ProgressView().controlSize(.small); Text("Loading...").font(.system(size: 11)).foregroundStyle(t.textTertiary); Spacer() }.padding(20)
                    } else if let info = vm.networkInfo {
                        // Cards
                        HStack(spacing: 12) {
                            infoCard("Hostname", info.hostname, "desktopcomputer", t.info)
                            infoCard("Public IP", info.publicIP ?? "Unavailable", "globe", t.accent)
                        }

                        // Local IPs
                        VStack(alignment: .leading, spacing: 6) {
                            Text("LOCAL INTERFACES").font(.system(size: 9.5, weight: .heavy, design: .rounded)).foregroundStyle(t.textTertiary).tracking(0.8)
                            ForEach(Array(info.localIPs.enumerated()), id: \.offset) { _, iface in
                                HStack(spacing: 10) {
                                    Text(iface.interface)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(t.accent)
                                        .frame(width: 50, alignment: .trailing)
                                    Text(iface.ip)
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundStyle(t.text)
                                        .textSelection(.enabled)
                                    StatusBadge(text: iface.type, style: .info)
                                    Spacer()
                                    Button { vm.copyIP(iface.ip); appState.showToast("Copied", icon: "doc.on.doc") } label: {
                                        Image(systemName: "doc.on.doc").font(.system(size: 9)).foregroundStyle(t.textTertiary)
                                    }.buttonStyle(.plain)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(t.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.border, lineWidth: 0.5))
                            }
                        }

                        // DNS Servers
                        if !info.dnsServers.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("DNS SERVERS").font(.system(size: 9.5, weight: .heavy, design: .rounded)).foregroundStyle(t.textTertiary).tracking(0.8)
                                HStack(spacing: 8) {
                                    ForEach(info.dnsServers, id: \.self) { server in
                                        Text(server)
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .foregroundStyle(t.text)
                                            .padding(.horizontal, 10).padding(.vertical, 6)
                                            .background(t.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(t.border, lineWidth: 0.5))
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle().fill(t.border).frame(height: 1)

                // DNS Lookup
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass").font(.system(size: 10, weight: .bold)).foregroundStyle(t.accent)
                        Text("DNS LOOKUP").font(.system(size: 9.5, weight: .heavy, design: .rounded)).foregroundStyle(t.textTertiary).tracking(0.8)
                    }

                    HStack(spacing: 8) {
                        TextField("example.com", text: $vm.dnsQuery)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 12).padding(.vertical, 10)
                            .background(t.editorBg)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(t.border, lineWidth: 1))
                            .onSubmit { vm.lookupDNS() }

                        DXButton(title: "Lookup", icon: "magnifyingglass") { vm.lookupDNS() }
                    }

                    if vm.isDNSLoading {
                        HStack { Spacer(); ProgressView().controlSize(.small); Text("Resolving...").font(.system(size: 11)).foregroundStyle(t.textTertiary); Spacer() }.padding(12)
                    }

                    if let dns = vm.dnsResult {
                        HStack(spacing: 12) {
                            StatusBadge(text: "\(dns.records.count) records", style: .success)
                            Text(String(format: "%.0fms", dns.resolveTime * 1000))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(t.textTertiary)
                        }

                        // Group by type
                        let types = Array(Set(dns.records.map(\.type))).sorted()
                        ForEach(types, id: \.self) { type in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(type)
                                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                                    .foregroundStyle(dnsTypeColor(type))
                                    .tracking(0.8)
                                ForEach(dns.records.filter { $0.type == type }) { record in
                                    HStack {
                                        Text(record.value)
                                            .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                                            .foregroundStyle(t.text)
                                            .textSelection(.enabled)
                                        Spacer()
                                        Button { vm.copyIP(record.value); appState.showToast("Copied") } label: {
                                            Image(systemName: "doc.on.doc").font(.system(size: 9)).foregroundStyle(t.textTertiary)
                                        }.buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(t.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(t.border, lineWidth: 0.5))
                                }
                            }
                        }

                        if dns.records.isEmpty {
                            Text("No records found")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(t.textTertiary)
                                .padding(12)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(t.bg)
        .onAppear { vm.loadNetworkInfo() }
        } // VStack
    }

    func infoCard(_ title: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 10, weight: .bold)).foregroundStyle(color)
                Text(title.uppercased()).font(.system(size: 9, weight: .heavy, design: .rounded)).foregroundStyle(t.textTertiary).tracking(0.8)
            }
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(t.text)
                .textSelection(.enabled)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(t.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(t.border, lineWidth: 0.5))
    }

    func dnsTypeColor(_ type: String) -> Color {
        switch type {
        case "A": return t.accent
        case "AAAA": return t.info
        case "CNAME": return t.success
        case "MX": return t.warning
        case "NS": return t.error
        case "TXT": return t.textSecondary
        default: return t.textTertiary
        }
    }
}
