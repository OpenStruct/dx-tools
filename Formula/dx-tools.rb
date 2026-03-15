class DxTools < Formula
  desc "23 developer tools in one CLI — JSON, JWT, ports, hashing, base64, UUID & more"
  homepage "https://openstruct.github.io/dx-tools/"
  url "https://github.com/OpenStruct/dx-tools/archive/refs/tags/v2.0.0.tar.gz"
  sha256 ""  # Updated on release
  license "MIT"
  head "https://github.com/OpenStruct/dx-tools.git", branch: "main"

  depends_on xcode: ["15.0", :build]
  depends_on :macos

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/dx"
  end

  test do
    assert_match "dx", shell_output("#{bin}/dx --help")
    assert_match(/[0-9a-f]{8}-/, shell_output("#{bin}/dx uuid"))
  end
end
