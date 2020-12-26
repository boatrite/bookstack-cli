require "open3"
require "tempfile"

RSpec.describe Bookstack::Cli do
  it "has a version number" do
    expect(Bookstack::Cli::VERSION).not_to be nil
  end

  let(:env_sh_path) { File.expand_path File.join __dir__, "../fixtures/env.sh" }
  let(:env) { "source #{env_sh_path}" }
  let(:bookstack_cli_cmd) { "bundle exec bookstack-cli" }

  it "correctly exports markdeep page game-boy-advance-development-with-mruby" do
    expected_file = File.join __dir__, "../fixtures/game-boy-advance-development-with-mruby.md.html"
    expected_contents = File.read(expected_file).strip # don't care about trailing newlines

    Tempfile.create do |output_file|
      expected_output = <<~STR
        Found .session-cache
        Cookie is valid
        Writing /tmp/game-boy-advance-development-with-mruby/first_rom.png
        Writing /tmp/game-boy-advance-development-with-mruby/mruby_rom.gif
        Writing /tmp/game-boy-advance-development-with-mruby/mruby_rom.png
        Writing /tmp/game-boy-advance-development-with-mruby/rom_on_gba.jpg
        Writing /tmp/game-boy-advance-development-with-mruby/bytecode.png
        Writing /tmp/game-boy-advance-development-with-mruby/final-demo.png
        Writing /tmp/game-boy-advance-development-with-mruby/final-debug.png
        Overwriting #{output_file.path}
      STR
      cmd = "#{env} && #{bookstack_cli_cmd} export pages books/blog-posts/page/game-boy-advance-development-with-mruby --output_file=#{output_file.path} --markdeep"
      wrapper_cmd = "bash -c '#{cmd}'"

      actual_output, _stderr, _status = Open3.capture3 wrapper_cmd
      actual_contents = File.read output_file.path

      expect(actual_output).to eq expected_output
      expect(actual_contents).to eq expected_contents
    ensure
      %w[
        /tmp/game-boy-advance-development-with-mruby/first_rom.png
        /tmp/game-boy-advance-development-with-mruby/mruby_rom.gif
        /tmp/game-boy-advance-development-with-mruby/mruby_rom.png
        /tmp/game-boy-advance-development-with-mruby/rom_on_gba.jpg
        /tmp/game-boy-advance-development-with-mruby/bytecode.png
        /tmp/game-boy-advance-development-with-mruby/final-demo.png
        /tmp/game-boy-advance-development-with-mruby/final-debug.png
      ].each do |path|
        File.delete path
      rescue => e
        warn "Unable to delete #{path}. Skipping. Original error: '#{e}'"
      end
    end
  end
end
