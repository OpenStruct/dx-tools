import Foundation
import Network

struct NetworkService {

    struct NetworkInfo {
        let hostname: String
        let localIPs: [(interface: String, ip: String, type: String)]
        let publicIP: String?
        let dnsServers: [String]
    }

    struct DNSResult {
        let domain: String
        let records: [DNSRecord]
        let resolveTime: TimeInterval
    }

    struct DNSRecord: Identifiable {
        let id = UUID()
        let type: String    // A, AAAA, CNAME, MX, NS, TXT
        let value: String
        let ttl: String
    }

    // MARK: - Network Info

    static func getNetworkInfo() -> NetworkInfo {
        let hostname = ProcessInfo.processInfo.hostName
        let localIPs = getLocalIPs()
        let publicIP = getPublicIP()
        let dns = getDNSServers()

        return NetworkInfo(
            hostname: hostname,
            localIPs: localIPs,
            publicIP: publicIP,
            dnsServers: dns
        )
    }

    static func getLocalIPs() -> [(interface: String, ip: String, type: String)] {
        var results: [(String, String, String)] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return results }
        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let addr = ptr {
            let name = String(cString: addr.pointee.ifa_name)
            let family = addr.pointee.ifa_addr.pointee.sa_family

            if family == UInt8(AF_INET) { // IPv4
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(addr.pointee.ifa_addr, socklen_t(addr.pointee.ifa_addr.pointee.sa_len),
                           &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                let ip = String(cString: hostname)
                if ip != "127.0.0.1" {
                    results.append((name, ip, "IPv4"))
                }
            } else if family == UInt8(AF_INET6) { // IPv6
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(addr.pointee.ifa_addr, socklen_t(addr.pointee.ifa_addr.pointee.sa_len),
                           &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                let ip = String(cString: hostname)
                if !ip.hasPrefix("fe80") && ip != "::1" { // Skip link-local and loopback
                    results.append((name, ip, "IPv6"))
                }
            }
            ptr = addr.pointee.ifa_next
        }
        return results
    }

    static func getPublicIP() -> String? {
        // Use a simple HTTP call to get public IP
        guard let url = URL(string: "https://api.ipify.org") else { return nil }
        var result: String?
        let sem = DispatchSemaphore(value: 0)

        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let ip = String(data: data, encoding: .utf8) {
                result = ip.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            sem.signal()
        }
        task.resume()
        _ = sem.wait(timeout: .now() + 5)
        return result
    }

    static func getDNSServers() -> [String] {
        let output = PortService.shell("scutil --dns 2>/dev/null | grep 'nameserver' | awk '{print $3}' | sort -u")
        return output.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // MARK: - DNS Lookup

    static func dnsLookup(domain: String) -> DNSResult {
        let start = CFAbsoluteTimeGetCurrent()
        var records: [DNSRecord] = []
        let cleanDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .components(separatedBy: "/").first ?? domain

        // A records
        let aOutput = PortService.shell("dig +short A \(cleanDomain) 2>/dev/null")
        for line in aOutput.split(separator: "\n") {
            let val = line.trimmingCharacters(in: .whitespaces)
            if !val.isEmpty {
                records.append(DNSRecord(type: "A", value: val, ttl: ""))
            }
        }

        // AAAA records
        let aaaaOutput = PortService.shell("dig +short AAAA \(cleanDomain) 2>/dev/null")
        for line in aaaaOutput.split(separator: "\n") {
            let val = line.trimmingCharacters(in: .whitespaces)
            if !val.isEmpty {
                records.append(DNSRecord(type: "AAAA", value: val, ttl: ""))
            }
        }

        // CNAME
        let cnameOutput = PortService.shell("dig +short CNAME \(cleanDomain) 2>/dev/null")
        for line in cnameOutput.split(separator: "\n") {
            let val = line.trimmingCharacters(in: .whitespaces)
            if !val.isEmpty {
                records.append(DNSRecord(type: "CNAME", value: val, ttl: ""))
            }
        }

        // MX
        let mxOutput = PortService.shell("dig +short MX \(cleanDomain) 2>/dev/null")
        for line in mxOutput.split(separator: "\n") {
            let val = line.trimmingCharacters(in: .whitespaces)
            if !val.isEmpty {
                records.append(DNSRecord(type: "MX", value: val, ttl: ""))
            }
        }

        // NS
        let nsOutput = PortService.shell("dig +short NS \(cleanDomain) 2>/dev/null")
        for line in nsOutput.split(separator: "\n") {
            let val = line.trimmingCharacters(in: .whitespaces)
            if !val.isEmpty {
                records.append(DNSRecord(type: "NS", value: val, ttl: ""))
            }
        }

        // TXT
        let txtOutput = PortService.shell("dig +short TXT \(cleanDomain) 2>/dev/null")
        for line in txtOutput.split(separator: "\n") {
            let val = line.trimmingCharacters(in: .whitespaces)
            if !val.isEmpty {
                records.append(DNSRecord(type: "TXT", value: val, ttl: ""))
            }
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start
        return DNSResult(domain: cleanDomain, records: records, resolveTime: elapsed)
    }
}
