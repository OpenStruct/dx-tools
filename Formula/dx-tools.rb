class DxTools < Formula
  desc "⚡ Developer Experience Toolkit - 17 tools in one native macOS app"
  homepage "https://github.com/cradx/dx-tools"
  url "https://github.com/cradx/dx-tools/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "PLACEHOLDER"
  license "MIT"

  depends_on xcode: ["15.0", :build]
  depends_on :macos

  def install
    # Install CLI tool
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/dx"

    # Build macOS app
    system "xcodegen", "generate"
    system "xcodebuild", "-project", "DXTools.xcodeproj",
           "-scheme", "DXTools",
           "-configuration", "Release",
           "-derivedDataPath", "build",
           "CODE_SIGN_IDENTITY=",
           "CODE_SIGNING_REQUIRED=NO",
           "CODE_SIGNING_ALLOWED=NO"

    app_path = Dir["build/Build/Products/Release/*.app"].first
    prefix.install app_path if app_path
  end

  test do
    assert_match "dx", shell_output("#{bin}/dx --version")
  end
end
