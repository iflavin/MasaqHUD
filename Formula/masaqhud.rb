class Masaqhud < Formula
  desc "Lightweight, scriptable desktop HUD for macOS"
  homepage "https://github.com/iflavin/MasaqHUD"
  url "https://github.com/iflavin/MasaqHUD/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "Apache-2.0"

  depends_on :macos
  depends_on xcode: ["14.0", :build]

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/MasaqHUD" => "masaqhud"
  end

  def caveats
    <<~EOS
      To get started:
        masaqhud init
        masaqhud start

      Configuration: ~/.config/masaqhud/masaqhud.js
      Documentation: https://github.com/iflavin/MasaqHUD/blob/main/docs/USER_GUIDE.md
    EOS
  end

  test do
    assert_match "MasaqHUD", shell_output("#{bin}/masaqhud --version")
  end
end
