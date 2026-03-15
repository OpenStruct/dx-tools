import Foundation

struct UnixPermService {

    struct Permission {
        let numeric: String     // "755"
        let symbolic: String    // "rwxr-xr-x"
        let octal: String       // "0755"
        let owner: String       // "rwx"
        let group: String       // "r-x"
        let others: String      // "r-x"
        let ownerDesc: String   // "Read, Write, Execute"
        let groupDesc: String
        let othersDesc: String
        let command: String     // "chmod 755 file"
        let lsFormat: String    // "-rwxr-xr-x"
        let isSetuid: Bool
        let isSetgid: Bool
        let isSticky: Bool
    }

    static func fromNumeric(_ input: String) -> Permission? {
        var cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("0o") { cleaned = String(cleaned.dropFirst(2)) }
        // Strip leading zero only if it gives us 3 digits (e.g., "0755" -> "755")
        while cleaned.count > 3 && cleaned.hasPrefix("0") {
            cleaned = String(cleaned.dropFirst())
        }
        guard cleaned.count == 3 || cleaned.count == 4,
              cleaned.allSatisfy({ $0 >= "0" && $0 <= "7" }) else { return nil }

        let digits = cleaned.count == 4 ? cleaned : "0" + cleaned
        let special = Int(String(digits[digits.startIndex]))!
        let o = Int(String(digits[digits.index(digits.startIndex, offsetBy: 1)]))!
        let g = Int(String(digits[digits.index(digits.startIndex, offsetBy: 2)]))!
        let t = Int(String(digits[digits.index(digits.startIndex, offsetBy: 3)]))!

        return build(owner: o, group: g, others: t, special: special)
    }

    static func fromSymbolic(_ input: String) -> Permission? {
        var cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("-") || cleaned.hasPrefix("d") || cleaned.hasPrefix("l") {
            cleaned = String(cleaned.dropFirst())
        }
        guard cleaned.count == 9 else { return nil }

        func parseTriple(_ s: String) -> Int? {
            guard s.count == 3 else { return nil }
            var val = 0
            if s[s.startIndex] == "r" { val += 4 }
            if s[s.index(s.startIndex, offsetBy: 1)] == "w" { val += 2 }
            let exec = s[s.index(s.startIndex, offsetBy: 2)]
            if exec == "x" || exec == "s" || exec == "S" || exec == "t" || exec == "T" { val += 1 }
            return val
        }

        let ownerStr = String(cleaned.prefix(3))
        let groupStr = String(cleaned.dropFirst(3).prefix(3))
        let othersStr = String(cleaned.dropFirst(6).prefix(3))

        guard let o = parseTriple(ownerStr),
              let g = parseTriple(groupStr),
              let t = parseTriple(othersStr) else { return nil }

        var special = 0
        if ownerStr.last == "s" || ownerStr.last == "S" { special += 4 }
        if groupStr.last == "s" || groupStr.last == "S" { special += 2 }
        if othersStr.last == "t" || othersStr.last == "T" { special += 1 }

        return build(owner: o, group: g, others: t, special: special)
    }

    private static func build(owner o: Int, group g: Int, others t: Int, special: Int) -> Permission {
        func toSymbolic(_ val: Int) -> String {
            let r = val & 4 != 0 ? "r" : "-"
            let w = val & 2 != 0 ? "w" : "-"
            let x = val & 1 != 0 ? "x" : "-"
            return r + w + x
        }
        func describe(_ val: Int) -> String {
            var parts: [String] = []
            if val & 4 != 0 { parts.append("Read") }
            if val & 2 != 0 { parts.append("Write") }
            if val & 1 != 0 { parts.append("Execute") }
            return parts.isEmpty ? "None" : parts.joined(separator: ", ")
        }

        var ownerSym = toSymbolic(o)
        var groupSym = toSymbolic(g)
        var othersSym = toSymbolic(t)

        // Apply special bits to symbolic
        if special & 4 != 0 {
            let last = o & 1 != 0 ? "s" : "S"
            ownerSym = String(ownerSym.dropLast()) + last
        }
        if special & 2 != 0 {
            let last = g & 1 != 0 ? "s" : "S"
            groupSym = String(groupSym.dropLast()) + last
        }
        if special & 1 != 0 {
            let last = t & 1 != 0 ? "t" : "T"
            othersSym = String(othersSym.dropLast()) + last
        }

        let symbolic = ownerSym + groupSym + othersSym
        let numeric = "\(o)\(g)\(t)"
        let fullOctal = special > 0 ? "\(special)\(numeric)" : "0\(numeric)"

        return Permission(
            numeric: numeric,
            symbolic: symbolic,
            octal: fullOctal,
            owner: ownerSym,
            group: groupSym,
            others: othersSym,
            ownerDesc: describe(o),
            groupDesc: describe(g),
            othersDesc: describe(t),
            command: "chmod \(special > 0 ? fullOctal : numeric) <file>",
            lsFormat: "-" + symbolic,
            isSetuid: special & 4 != 0,
            isSetgid: special & 2 != 0,
            isSticky: special & 1 != 0
        )
    }

    static let commonPermissions: [(numeric: String, description: String)] = [
        ("755", "Owner: rwx, Group/Others: rx — Standard for directories & executables"),
        ("644", "Owner: rw, Group/Others: r — Standard for files"),
        ("700", "Owner: rwx — Private directory"),
        ("600", "Owner: rw — Private file (SSH keys)"),
        ("777", "Everyone: rwx — Full access (avoid!)"),
        ("750", "Owner: rwx, Group: rx — Shared directory"),
        ("664", "Owner/Group: rw, Others: r — Shared file"),
        ("400", "Owner: r — Read-only (certificates)"),
    ]
}
