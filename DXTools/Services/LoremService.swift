import Foundation

struct LoremService {

    private static let words = [
        "lorem", "ipsum", "dolor", "sit", "amet", "consectetur", "adipiscing", "elit",
        "sed", "do", "eiusmod", "tempor", "incididunt", "ut", "labore", "et", "dolore",
        "magna", "aliqua", "enim", "ad", "minim", "veniam", "quis", "nostrud",
        "exercitation", "ullamco", "laboris", "nisi", "aliquip", "ex", "ea", "commodo",
        "consequat", "duis", "aute", "irure", "in", "reprehenderit", "voluptate",
        "velit", "esse", "cillum", "fugiat", "nulla", "pariatur", "excepteur", "sint",
        "occaecat", "cupidatat", "non", "proident", "sunt", "culpa", "qui", "officia",
        "deserunt", "mollit", "anim", "id", "est", "laborum", "at", "vero", "eos",
        "accusamus", "iusto", "odio", "dignissimos", "ducimus", "blanditiis",
        "praesentium", "voluptatum", "deleniti", "atque", "corrupti", "quos", "dolores",
        "quas", "molestias", "excepturi", "obcaecati", "cupiditate", "provident",
        "similique", "architecto", "beatae", "vitae", "dicta", "explicabo", "nemo",
        "ipsam", "voluptatem", "quia", "voluptas", "aspernatur", "aut", "odit", "fugit"
    ]

    private static let firstNames = [
        "James", "Emma", "Liam", "Olivia", "Noah", "Ava", "William", "Sophia",
        "Oliver", "Isabella", "Elijah", "Mia", "Lucas", "Charlotte", "Mason", "Amelia",
        "Logan", "Harper", "Alexander", "Evelyn", "Ethan", "Abigail", "Daniel", "Emily",
        "Nam", "Aiko", "Raj", "Fatima", "Chen", "Sofia", "Kai", "Yuki"
    ]

    private static let lastNames = [
        "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
        "Rodriguez", "Martinez", "Wilson", "Anderson", "Taylor", "Thomas", "Moore",
        "Nguyen", "Tanaka", "Patel", "Kim", "Chen", "Ali", "Singh", "Mueller", "Santos"
    ]

    private static let domains = ["gmail.com", "outlook.com", "yahoo.com", "example.com", "company.io", "dev.co"]

    static func generateWords(_ count: Int) -> String {
        (0..<count).map { _ in words.randomElement()! }.joined(separator: " ")
    }

    static func generateSentence(wordCount: Int = 0) -> String {
        let count = wordCount > 0 ? wordCount : Int.random(in: 8...16)
        var sentence = generateWords(count)
        sentence = sentence.prefix(1).uppercased() + sentence.dropFirst()
        sentence += "."
        return sentence
    }

    static func generateParagraph(sentenceCount: Int = 0) -> String {
        let count = sentenceCount > 0 ? sentenceCount : Int.random(in: 4...8)
        return (0..<count).map { _ in generateSentence() }.joined(separator: " ")
    }

    static func generateParagraphs(_ count: Int) -> String {
        (0..<count).map { _ in generateParagraph() }.joined(separator: "\n\n")
    }

    static func generateName() -> String {
        "\(firstNames.randomElement()!) \(lastNames.randomElement()!)"
    }

    static func generateEmail() -> String {
        let first = firstNames.randomElement()!.lowercased()
        let last = lastNames.randomElement()!.lowercased()
        let domain = domains.randomElement()!
        let formats = ["\(first).\(last)@\(domain)", "\(first)\(Int.random(in: 1...99))@\(domain)", "\(first.prefix(1))\(last)@\(domain)"]
        return formats.randomElement()!
    }

    static func generatePhone() -> String {
        let area = Int.random(in: 200...999)
        let mid = Int.random(in: 100...999)
        let end = Int.random(in: 1000...9999)
        return "+1 (\(area)) \(mid)-\(end)"
    }

    static func generateAddress() -> String {
        let streets = ["Main St", "Oak Ave", "Elm St", "Park Blvd", "Cedar Rd", "Maple Dr", "Pine St", "River Rd"]
        let cities = ["New York", "London", "Tokyo", "Berlin", "Sydney", "Mumbai", "Toronto", "Paris"]
        return "\(Int.random(in: 1...9999)) \(streets.randomElement()!), \(cities.randomElement()!)"
    }

    static func generateJSON(count: Int) -> String {
        var users: [[String: Any]] = []
        for i in 0..<count {
            let user: [String: Any] = [
                "id": i + 1,
                "name": generateName(),
                "email": generateEmail(),
                "phone": generatePhone(),
                "address": generateAddress(),
                "active": Bool.random()
            ]
            users.append(user)
        }
        if let data = try? JSONSerialization.data(withJSONObject: users, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "[]"
    }
}
