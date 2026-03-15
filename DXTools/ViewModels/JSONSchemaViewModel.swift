import SwiftUI

@Observable
class JSONSchemaViewModel {
    var jsonInput: String = ""
    var schemaInput: String = ""
    var result: JSONSchemaService.ValidationResult?

    func validate() {
        guard !jsonInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !schemaInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            result = nil
            return
        }
        result = JSONSchemaService.validate(json: jsonInput, against: schemaInput)
    }

    func autoValidate() {
        let json = jsonInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let schema = schemaInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !json.isEmpty, !schema.isEmpty,
              json.hasPrefix("{") || json.hasPrefix("["),
              schema.hasPrefix("{") else {
            result = nil
            return
        }
        validate()
    }

    func sample() {
        jsonInput = """
        {
          "name": "Alice",
          "age": 30,
          "email": "alice@example.com",
          "tags": ["admin", "user"]
        }
        """
        schemaInput = """
        {
          "type": "object",
          "required": ["name", "age", "email"],
          "properties": {
            "name": { "type": "string", "minLength": 1 },
            "age": { "type": "integer", "minimum": 0, "maximum": 150 },
            "email": { "type": "string", "pattern": "^.+@.+\\\\..+$" },
            "tags": { "type": "array", "items": { "type": "string" } }
          }
        }
        """
        validate()
    }
}
