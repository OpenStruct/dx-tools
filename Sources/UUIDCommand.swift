import ArgumentParser
import Foundation

struct UUIDCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "uuid",
        abstract: "Generate & inspect UUIDs"
    )
    
    @Argument(help: "Number of UUIDs to generate")
    var count: Int = 1
    
    @Flag(name: .shortAndLong, help: "Uppercase output")
    var upper: Bool = false
    
    @Flag(name: .shortAndLong, help: "No dashes")
    var compact: Bool = false
    
    func run() {
        print(Style.header("🎲", "uuid"))
        print()
        
        for i in 0..<count {
            var uuid = UUID().uuidString
            if !upper { uuid = uuid.lowercased() }
            if compact { uuid = uuid.replacingOccurrences(of: "-", with: "") }
            
            if count == 1 {
                print("  \(Style.yellow)\(uuid)\(Style.reset)")
                print()
                print(Style.label("Version", "4 (random)"))
                print(Style.label("Bytes", "16"))
                print(Style.label("Bits", "128"))
            } else {
                let num = String(format: "%3d", i + 1)
                print("  \(Style.gray)\(num).\(Style.reset) \(Style.yellow)\(uuid)\(Style.reset)")
            }
        }
        print()
    }
}
