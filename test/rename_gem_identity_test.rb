# frozen_string_literal: true

require "test_helper"

class RenameGemIdentityTest < Minitest::Test
  def test_rename_script_and_template_docs_are_gone
    root = File.expand_path("..", __dir__)

    refute File.exist?(File.join(root, "bin", "rename_gem"))
    refute File.exist?(File.join(root, "test", "rename_verification_test.rb"))
    refute File.exist?(File.join(root, "docs", "gem_template"))
  end
end
