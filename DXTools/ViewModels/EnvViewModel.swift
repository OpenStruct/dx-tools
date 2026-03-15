import SwiftUI

@Observable
class EnvViewModel {
    var input: String = ""
    var entries: [EnvService.EnvEntry] = []
    var revealed: Bool = false
    var errorMessage: String?

    // Diff
    var diffBase: String = ""
    var diffCompare: String = ""
    var diffResult: EnvService.DiffResult?

    var mode: Mode = .view

    enum Mode: String, CaseIterable {
        case view = "View"
        case diff = "Diff"
    }

    func parse() {
        entries = EnvService.parse(input)
    }

    func runDiff() {
        guard !diffBase.isEmpty, !diffCompare.isEmpty else {
            diffResult = nil; return
        }
        diffResult = EnvService.diff(base: diffBase, compare: diffCompare)
    }

    func clear() {
        input = ""; entries = []; diffBase = ""; diffCompare = ""; diffResult = nil
    }

    func loadSample() {
        input = """
        # Database
        DB_HOST=localhost
        DB_PORT=5432
        DB_NAME=myapp_dev
        DB_PASSWORD="super_secret_123"

        # API Keys
        API_KEY=sk-1234567890abcdef
        STRIPE_SECRET_KEY=sk_test_abc123xyz
        JWT_SECRET=my-jwt-secret-key

        # App Config
        APP_NAME=DX Tools
        APP_ENV=development
        DEBUG=true
        PORT=3000

        # AWS
        AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
        AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
        AWS_REGION=us-east-1
        """
        parse()
    }

    func loadDiffSample() {
        diffBase = """
        DB_HOST=localhost
        DB_PORT=5432
        DB_PASSWORD="dev_password"
        API_KEY=sk-dev-key
        APP_ENV=development
        DEBUG=true
        """

        diffCompare = """
        DB_HOST=prod-db.example.com
        DB_PORT=5432
        DB_PASSWORD="prod_password_xyz"
        API_KEY=sk-prod-key
        APP_ENV=production
        DEBUG=false
        REDIS_URL=redis://prod-cache:6379
        """
        runDiff()
    }
}
