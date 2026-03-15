import SwiftUI

@Observable
class NetworkViewModel {
    var networkInfo: NetworkService.NetworkInfo?
    var dnsQuery = ""
    var dnsResult: NetworkService.DNSResult?
    var isLoading = false
    var isDNSLoading = false

    func loadNetworkInfo() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let info = NetworkService.getNetworkInfo()
            DispatchQueue.main.async {
                self.networkInfo = info
                self.isLoading = false
            }
        }
    }

    func lookupDNS() {
        guard !dnsQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isDNSLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = NetworkService.dnsLookup(domain: self.dnsQuery)
            DispatchQueue.main.async {
                self.dnsResult = result
                self.isDNSLoading = false
            }
        }
    }

    func copyIP(_ ip: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(ip, forType: .string)
    }
}
