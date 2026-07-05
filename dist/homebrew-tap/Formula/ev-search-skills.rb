# Homebrew formula for the EV Search Skills suite.
#
# This file belongs in your TAP repo (github.com/pingvinen/homebrew-tap) at:
#   Formula/ev-search-skills.rb
#
# HEAD-only for now — installs straight from main:
#   brew tap pingvinen/tap
#   brew install --HEAD ev-search-skills
#
# The stable (SemVer) line is intentionally deferred until the CI/CD pipeline is in
# place — it will add `url`/`sha256` for a tagged tarball and auto-bump on release.
# See PUBLISHING.md → "Stable releases (deferred until CI/CD)".
class EvSearchSkills < Formula
  desc "Claude Code skills that research & compare EVs for the Danish market"
  homepage "https://github.com/pingvinen/ev-search-skills"
  license :cannot_represent # PolyForm Noncommercial 1.0.0 — see LICENSE
  head "https://github.com/pingvinen/ev-search-skills.git", branch: "main"

  def install
    libexec.install ".claude", "bin", "state.md", "search_criteria.md",
                    "car-template.md", "README.md", "LICENSE"
    chmod 0755, libexec/"bin/ev-search-skills"
    (bin/"ev-search-skills").write_env_script libexec/"bin/ev-search-skills",
                                              EV_SKILLS_HOME: libexec
  end

  def caveats
    <<~EOS
      Install the /ev-* skills into Claude Code, then scaffold a workspace:

        ev-search-skills install
        ev-search-skills scaffold my-ev-search

      Start Claude Code in the workspace and run /ev-new-project to begin.
    EOS
  end

  test do
    assert_match(/\d+\.\d+\.\d+/, shell_output("#{bin}/ev-search-skills version"))
    system bin/"ev-search-skills", "scaffold", testpath/"ws"
    assert_predicate testpath/"ws/state.md", :exist?
    assert_predicate testpath/"ws/search_criteria.md", :exist?
  end
end
