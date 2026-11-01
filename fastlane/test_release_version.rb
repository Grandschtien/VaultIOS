# Run with: /opt/homebrew/opt/ruby/bin/ruby fastlane/test_release_version.rb
require "minitest/autorun"
require_relative "release_version"

class ReleaseVersionTest < Minitest::Test
  PBXPROJ = File.read(File.expand_path("../Vault.xcodeproj/project.pbxproj", __dir__))

  def test_release_moves_to_next_free_minor
    assert_equal "1.4", ReleaseVersion.resolve_release_version("1.3", {})
    assert_equal "1.4", ReleaseVersion.resolve_release_version("1.3", { "1.3" => "READY_FOR_SALE" })
    states = { "1.3" => "READY_FOR_SALE", "1.4" => "REPLACED_WITH_NEW_VERSION" }
    assert_equal "1.5", ReleaseVersion.resolve_release_version("1.3", states)
  end

  def test_release_stops_while_a_version_is_open
    %w[IN_REVIEW PREPARE_FOR_SUBMISSION].each do |state|
      error = assert_raises(RuntimeError) { ReleaseVersion.resolve_release_version("1.3", { "1.3" => state }) }
      assert_match state, error.message
    end
  end

  def test_requested_release_version_wins_unless_taken
    assert_equal "2.0", ReleaseVersion.resolve_release_version("1.3", {}, "2.0")
    assert_raises(RuntimeError) { ReleaseVersion.resolve_release_version("1.3", { "1.3" => "READY_FOR_SALE" }, "1.3") }
  end

  def test_beta_keeps_the_open_version
    assert_equal "1.3", ReleaseVersion.resolve_beta_version("1.3", {})
    assert_equal "1.3", ReleaseVersion.resolve_beta_version("1.3", { "1.3" => "PREPARE_FOR_SUBMISSION" })
    assert_equal "1.3", ReleaseVersion.resolve_beta_version("1.3", { "1.3" => "IN_REVIEW" })
  end

  def test_beta_stops_on_an_approved_version
    assert_raises(RuntimeError) { ReleaseVersion.resolve_beta_version("1.3", { "1.3" => "READY_FOR_SALE" }) }
  end

  def test_build_is_above_local_and_uploaded
    assert_equal 8, ReleaseVersion.resolve_build(4, 7)
    assert_equal 10, ReleaseVersion.resolve_build(9, 7)
    assert_equal 4, ReleaseVersion.resolve_build(0, 3)
  end

  def test_latest_release_tag_skips_testflight_builds
    assert_equal "v1.4", ReleaseVersion.latest_release_tag(%w[v1.4-3 v1.4-2 v1.4 v1.3])
    assert_nil ReleaseVersion.latest_release_tag(%w[v1.4-3])
  end

  def test_change_bases
    assert_equal %w[abc abc], ReleaseVersion.change_bases([], "abc")
    assert_equal %w[v1.4-6 v1.4], ReleaseVersion.change_bases(%w[v1.4-6 v1.4 v1.3], "abc")
    assert_equal %w[v1.3 v1.3], ReleaseVersion.change_bases(%w[v1.3], "abc")
    assert_equal %w[v1.4-6 abc], ReleaseVersion.change_bases(%w[v1.4-6], "abc")
  end

  def test_project_file_updates_only_app_and_widget
    updated = ReleaseVersion.apply_versions(PBXPROJ, "9.8", 76)
    assert_equal ["9.8", 76], ReleaseVersion.read_local_versions(updated)
    assert_equal 4, updated.scan("MARKETING_VERSION = 9.8;").size
    assert_equal 4, updated.scan("CURRENT_PROJECT_VERSION = 76;").size
    assert_equal PBXPROJ.scan("MARKETING_VERSION = 1.0;").size, updated.scan("MARKETING_VERSION = 1.0;").size
    assert_equal PBXPROJ.count("\n"), updated.count("\n")
  end
end
