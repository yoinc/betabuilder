require 'rest_client'
require 'json'
require 'tmpdir'
require 'fileutils'

module BetaBuilder
  module DeploymentStrategies
    class Crashlytics < Strategy
      def extended_configuration_for_strategy
        proc do
          def generate_release_notes(&block)
            self.release_notes = block if block
          end
        end
      end

      def deploy
        release_notes = @configuration.release_notes.call
        puts "Release notes are #{release_notes}"
        puts "ipa_path: #{@configuration.ipa_path}"
        dir = Dir.mktmpdir
        begin
          filepath = "#{dir}/release_notes.txt"
          res = IO.write(filepath, release_notes)
          unless res
            puts "Failed to create temp release notes file"
          else
            puts "Distributing build on Crashlytics... #{@configuration.framework_path}/Crashlytics.framework/submit"
            res = system("#{@configuration.framework_path}Crashlytics.framework/submit #{@configuration.api_key} #{@configuration.build_secret} -ipaPath #{@configuration.ipa_path} -emails #{@configuration.emails} -notesPath #{filepath}")
            if res
              puts "Upload complete."
            else
              puts "Upload failed: #{res}."
            end
          end
        ensure
          FileUtils.rm_rf(dir)
        end
      end
    end
  end
end