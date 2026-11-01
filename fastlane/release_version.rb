# Version rules of the release flow. Plain Ruby, so test_release_version.rb runs without App Store Connect.
module ReleaseVersion
  EDITABLE_STATES = %w[
    PREPARE_FOR_SUBMISSION READY_FOR_REVIEW DEVELOPER_REJECTED REJECTED METADATA_REJECTED INVALID_BINARY
  ].freeze
  IN_REVIEW_STATES = %w[WAITING_FOR_REVIEW IN_REVIEW WAITING_FOR_EXPORT_COMPLIANCE PENDING_CONTRACT].freeze
  VERSIONED_BUNDLE_IDS = %w[com.egor.shkarin.Vault com.egor.shkarin.Vault.widget].freeze
  BUILD_SETTINGS = /buildSettings = \{.*?\n\t\t\t\};/m

  module_function

  def next_minor(version)
    major, minor = version.split(".")
    "#{major}.#{minor.to_i + 1}"
  end

  # states: { "1.3" => "READY_FOR_SALE" }. App Store Connect keeps one open version, so it must be closed first.
  def resolve_release_version(local_version, states, requested = nil)
    open_version, open_state = states.find { |_, state| (EDITABLE_STATES + IN_REVIEW_STATES).include?(state) }
    raise "Version #{open_version} is #{open_state}, finish or remove it first" if open_version

    candidate = requested || next_minor(local_version)
    return candidate unless states[candidate]
    raise "Version #{candidate} is already #{states[candidate]}" if requested

    resolve_release_version(candidate, states)
  end

  # A train stays open for new builds until its version is approved.
  def resolve_beta_version(local_version, states)
    state = states[local_version]
    return local_version if state.nil? || (EDITABLE_STATES + IN_REVIEW_STATES).include?(state)

    raise "Version #{local_version} is already #{state}, ship a new version with release"
  end

  # The local number covers an upload App Store Connect does not list yet.
  def resolve_build(local_build, uploaded_build)
    [local_build, uploaded_build].max + 1
  end

  # Release tags look like v1.4, while v1.4-6 is a TestFlight build.
  def latest_release_tag(tags)
    tags.find { |tag| !tag.include?("-") }
  end

  # TestFlight notes start at the last tag, What's New at the last release tag.
  def change_bases(tags, fallback)
    [tags.first || fallback, latest_release_tag(tags) || fallback]
  end

  def read_local_versions(pbxproj)
    block = pbxproj.scan(BUILD_SETTINGS).find { |item| item.include?("PRODUCT_BUNDLE_IDENTIFIER = #{VERSIONED_BUNDLE_IDS.first};") }
    raise "App build settings were not found" unless block

    [block[/MARKETING_VERSION = ([^;]+);/, 1], block[/CURRENT_PROJECT_VERSION = (\d+);/, 1].to_i]
  end

  # Edited as text: saving through xcodeproj would reformat the whole project file.
  def apply_versions(pbxproj, version, build)
    pbxproj.gsub(BUILD_SETTINGS) do |block|
      next block unless VERSIONED_BUNDLE_IDS.include?(block[/PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);/, 1])

      block.sub(/MARKETING_VERSION = [^;]+;/, "MARKETING_VERSION = #{version};")
           .sub(/CURRENT_PROJECT_VERSION = [^;]+;/, "CURRENT_PROJECT_VERSION = #{build};")
    end
  end
end
