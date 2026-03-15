import Foundation

struct JSONDiffService {

    enum DiffType {
        case added, removed, changed, same
    }

    struct DiffEntry: Identifiable {
        let id = UUID()
        let path: String
        let type: DiffType
        let oldValue: String?
        let newValue: String?
        let depth: Int
    }

    static func diff(left: String, right: String) -> Result<[DiffEntry], Error> {
        guard let leftData = left.data(using: .utf8),
              let rightData = right.data(using: .utf8) else {
            return .failure(DiffError.invalidUTF8)
        }

        do {
            let leftObj = try JSONSerialization.jsonObject(with: leftData, options: .fragmentsAllowed)
            let rightObj = try JSONSerialization.jsonObject(with: rightData, options: .fragmentsAllowed)

            var entries: [DiffEntry] = []
            compare(leftObj, rightObj, path: "$", depth: 0, entries: &entries)
            return .success(entries)
        } catch {
            return .failure(error)
        }
    }

    private static func compare(_ left: Any, _ right: Any, path: String, depth: Int, entries: inout [DiffEntry]) {
        if let ld = left as? [String: Any], let rd = right as? [String: Any] {
            let allKeys = Set(ld.keys).union(Set(rd.keys)).sorted()
            for key in allKeys {
                let childPath = "\(path).\(key)"
                if let lv = ld[key], let rv = rd[key] {
                    compare(lv, rv, path: childPath, depth: depth + 1, entries: &entries)
                } else if let lv = ld[key] {
                    entries.append(DiffEntry(path: childPath, type: .removed, oldValue: stringify(lv), newValue: nil, depth: depth + 1))
                } else if let rv = rd[key] {
                    entries.append(DiffEntry(path: childPath, type: .added, oldValue: nil, newValue: stringify(rv), depth: depth + 1))
                }
            }
        } else if let la = left as? [Any], let ra = right as? [Any] {
            let maxCount = max(la.count, ra.count)
            for i in 0..<maxCount {
                let childPath = "\(path)[\(i)]"
                if i < la.count && i < ra.count {
                    compare(la[i], ra[i], path: childPath, depth: depth + 1, entries: &entries)
                } else if i < la.count {
                    entries.append(DiffEntry(path: childPath, type: .removed, oldValue: stringify(la[i]), newValue: nil, depth: depth + 1))
                } else {
                    entries.append(DiffEntry(path: childPath, type: .added, oldValue: nil, newValue: stringify(ra[i]), depth: depth + 1))
                }
            }
        } else {
            let ls = stringify(left)
            let rs = stringify(right)
            if ls == rs {
                entries.append(DiffEntry(path: path, type: .same, oldValue: ls, newValue: rs, depth: depth))
            } else {
                entries.append(DiffEntry(path: path, type: .changed, oldValue: ls, newValue: rs, depth: depth))
            }
        }
    }

    private static func stringify(_ value: Any) -> String {
        if value is NSNull { return "null" }
        if let s = value as? String { return "\"\(s)\"" }
        if let n = value as? NSNumber {
            if CFBooleanGetTypeID() == CFGetTypeID(n) { return n.boolValue ? "true" : "false" }
            return "\(n)"
        }
        if let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "\(value)"
    }

    enum DiffError: LocalizedError {
        case invalidUTF8
        var errorDescription: String? { "Invalid UTF-8 encoding" }
    }
}
