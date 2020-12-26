require "open3"
require "tempfile"

RSpec.describe Bookstack::Cli do
  it "has a version number" do
    expect(Bookstack::Cli::VERSION).not_to be nil
  end

  shared_examples "bookstack-cli export" do
    let(:env_sh_path) { File.expand_path File.join __dir__, "../fixtures/env.sh" }
    let(:env) { "source #{env_sh_path}" }
    let(:bookstack_cli_cmd) { "bundle exec bookstack-cli" }

    it "correctly exports" do
      expected_file = File.join __dir__, "../fixtures/#{expected_filename}"
      expected_contents = File.read(expected_file).strip # don't care about trailing newlines

      Tempfile.create do |output_file|
        cmd = "#{env} && #{bookstack_cli_cmd} #{command_params_lambda[output_file]}"
        wrapper_cmd = "bash -c '#{cmd}'"

        actual_output, _stderr, _status = Open3.capture3 wrapper_cmd
        actual_contents = File.read output_file.path

        expect(actual_output).to eq expected_output_lambda[output_file]
        expect(actual_contents).to eq expected_contents
      ensure
        auxilary_files.each do |path|
          File.delete path
        rescue => e
          warn "Unable to delete #{path}. Skipping. Original error: '#{e}'"
        end
      end
    end
  end

  context "markdeep page game-boy-advance-development-with-mruby" do
    include_examples "bookstack-cli export" do
      let(:command_params_lambda) {
        ->(output_file) {
          "export page books/blog-posts/page/game-boy-advance-development-with-mruby --output_file=#{output_file.path} --markdeep"
        }
      }

      let(:expected_filename) { "game-boy-advance-development-with-mruby.md.html" }

      let(:expected_output_lambda) {
        ->(output_file) {
          <<~STR
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
        }
      }

      let(:auxilary_files) {
        %w[
          /tmp/game-boy-advance-development-with-mruby/first_rom.png
          /tmp/game-boy-advance-development-with-mruby/mruby_rom.gif
          /tmp/game-boy-advance-development-with-mruby/mruby_rom.png
          /tmp/game-boy-advance-development-with-mruby/rom_on_gba.jpg
          /tmp/game-boy-advance-development-with-mruby/bytecode.png
          /tmp/game-boy-advance-development-with-mruby/final-demo.png
          /tmp/game-boy-advance-development-with-mruby/final-debug.png
        ]
      }
    end
  end

  context "markdown chapter creating-a-voxel-engine-from-scratch" do
    include_examples "bookstack-cli export" do
      let(:command_params_lambda) {
        ->(output_file) {
          "export chapter hot-creating-a-voxel-engine-from-scratch --output_file=#{output_file.path} --output_dir=creating-a-voxel-engine-from-scratch"
        }
      }

      let(:expected_filename) { "creating-a-voxel-engine-from-scratch.md" }

      let(:expected_output_lambda) {
        ->(output_file) {
          <<~STR
            Writing /tmp/creating-a-voxel-engine-from-scratch/dirt_plane.png
            Writing /tmp/creating-a-voxel-engine-from-scratch/screenshot_13.png
            Writing /tmp/creating-a-voxel-engine-from-scratch/chunk-loading-unloading.gif
            Writing /tmp/creating-a-voxel-engine-from-scratch/mesh_plane.png
            Writing /tmp/creating-a-voxel-engine-from-scratch/mesh_half_sphere.png
            Writing /tmp/creating-a-voxel-engine-from-scratch/gui.png
            Writing /tmp/creating-a-voxel-engine-from-scratch/multiple-block-types.gif
            Writing /tmp/creating-a-voxel-engine-from-scratch/procgen.png
            Writing /tmp/creating-a-voxel-engine-from-scratch/diffuse.png
            Writing /tmp/creating-a-voxel-engine-from-scratch/attenuation.png
            Writing /tmp/creating-a-voxel-engine-from-scratch/directional_and_point_lights.png
            Writing /tmp/creating-a-voxel-engine-from-scratch/shadows_with_acne.png
            Writing /tmp/creating-a-voxel-engine-from-scratch/shadows.gif
            Writing /tmp/creating-a-voxel-engine-from-scratch/day-night-1.gif
            Writing /tmp/creating-a-voxel-engine-from-scratch/day-night-2.gif
            Writing /tmp/creating-a-voxel-engine-from-scratch/boundary-lag.gif
            Writing /tmp/creating-a-voxel-engine-from-scratch/boundary-lag-fixed.gif
            Writing /tmp/creating-a-voxel-engine-from-scratch/multitexture_blocks.png
            Writing /tmp/creating-a-voxel-engine-from-scratch/scripted_worldgen.png
            Overwriting #{output_file.path}
          STR
        }
      }

      let(:auxilary_files) {
        %w[
          /tmp/creating-a-voxel-engine-from-scratch/dirt_plane.png
          /tmp/creating-a-voxel-engine-from-scratch/screenshot_13.png
          /tmp/creating-a-voxel-engine-from-scratch/chunk-loading-unloading.gif
          /tmp/creating-a-voxel-engine-from-scratch/mesh_plane.png
          /tmp/creating-a-voxel-engine-from-scratch/mesh_half_sphere.png
          /tmp/creating-a-voxel-engine-from-scratch/gui.png
          /tmp/creating-a-voxel-engine-from-scratch/multiple-block-types.gif
          /tmp/creating-a-voxel-engine-from-scratch/procgen.png
          /tmp/creating-a-voxel-engine-from-scratch/diffuse.png
          /tmp/creating-a-voxel-engine-from-scratch/attenuation.png
          /tmp/creating-a-voxel-engine-from-scratch/directional_and_point_lights.png
          /tmp/creating-a-voxel-engine-from-scratch/shadows_with_acne.png
          /tmp/creating-a-voxel-engine-from-scratch/shadows.gif
          /tmp/creating-a-voxel-engine-from-scratch/day-night-1.gif
          /tmp/creating-a-voxel-engine-from-scratch/day-night-2.gif
          /tmp/creating-a-voxel-engine-from-scratch/boundary-lag.gif
          /tmp/creating-a-voxel-engine-from-scratch/boundary-lag-fixed.gif
          /tmp/creating-a-voxel-engine-from-scratch/multitexture_blocks.png
          /tmp/creating-a-voxel-engine-from-scratch/scripted_worldgen.png
        ]
      }
    end
  end
end
