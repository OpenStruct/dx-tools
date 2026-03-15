import SwiftUI

@Observable
class TextDiffViewModel {
    var leftInput: String = ""
    var rightInput: String = ""
    var result: TextDiffService.DiffResult?
    var unifiedOutput: String = ""

    func compare() {
        guard !leftInput.isEmpty || !rightInput.isEmpty else {
            result = nil
            unifiedOutput = ""
            return
        }
        result = TextDiffService.diff(left: leftInput, right: rightInput)
        unifiedOutput = TextDiffService.unifiedDiff(left: leftInput, right: rightInput)
    }

    func clear() {
        leftInput = ""
        rightInput = ""
        result = nil
        unifiedOutput = ""
    }

    func swap() {
        let tmp = leftInput
        leftInput = rightInput
        rightInput = tmp
        compare()
    }

    func loadSample() {
        leftInput = """
        function greet(name) {
            console.log("Hello, " + name);
            return true;
        }

        const users = ["Alice", "Bob"];
        users.forEach(greet);
        """
        rightInput = """
        function greet(name, greeting = "Hello") {
            console.log(`${greeting}, ${name}!`);
            return true;
        }

        const users = ["Alice", "Bob", "Charlie"];
        users.forEach(user => greet(user));
        console.log("Done");
        """
        compare()
    }

    func copyUnified() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(unifiedOutput, forType: .string)
    }
}
