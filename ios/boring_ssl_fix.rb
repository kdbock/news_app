require 'pathname'
require 'fileutils'

module Pod
  class Target
    def add_compiler_flags_to_settings(settings, *flags)
      # Filter out the problematic -G flag specifically for BoringSSL-GRPC
      if name == 'BoringSSL-GRPC'
        filtered_flags = flags.flatten.reject { |f| f == '-G' }
        settings['OTHER_CFLAGS'] ||= '$(inherited)'
        settings['OTHER_CFLAGS'] += ' ' + filtered_flags.join(' ')
      else
        # Original implementation for other targets
        settings['OTHER_CFLAGS'] ||= '$(inherited)'
        settings['OTHER_CFLAGS'] += ' ' + flags.flatten.join(' ')
      end
    end

    def remove_g_flag_from_compiler_flags
      return unless name == 'BoringSSL-GRPC'
      
      build_configurations.each do |config|
        # Remove -G flag from all compiler flags
        if config.build_settings['OTHER_CFLAGS']
          config.build_settings['OTHER_CFLAGS'] = config.build_settings['OTHER_CFLAGS'].gsub(/-G/, '')
        end
        
        if config.build_settings['OTHER_CPPFLAGS']
          config.build_settings['OTHER_CPPFLAGS'] = config.build_settings['OTHER_CPPFLAGS'].gsub(/-G/, '')
        end
        
        # Set specific flags for BoringSSL to avoid other issues
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'OPENSSL_NO_ASM=1'
      end
    end
  end

  class Installer
    def fix_boringssl_for_arm64
      puts "Applying BoringSSL fix for ARM64..."
      
      # Find the target
      boring_ssl_target = pods_project.targets.find { |target| target.name == 'BoringSSL-GRPC' }
      return unless boring_ssl_target
      
      # Fix each build configuration
      boring_ssl_target.build_configurations.each do |config|
        # Remove the problematic -G flag from all compiler settings
        %w(OTHER_CFLAGS OTHER_CPPFLAGS OTHER_LDFLAGS).each do |setting|
          if config.build_settings[setting]
            config.build_settings[setting] = config.build_settings[setting].gsub(/-G/, '')
          end
        end
        
        # Add specific flags to help BoringSSL compile correctly
        config.build_settings['OTHER_CFLAGS'] = '$(inherited) -w -Xanalyzer -analyzer-disable-all-checks'
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'OPENSSL_NO_ASM=1'
      end
      
      puts "BoringSSL fix applied successfully"
    end

    # Add this method to the Installer class
    def patch_boringssl_for_xcode
      puts "🔨 Applying direct patch to BoringSSL-GRPC build files..."
      
      # Find the target
      boring_ssl_target = pods_project.targets.find { |target| target.name == 'BoringSSL-GRPC' }
      return unless boring_ssl_target

      # First, attempt to fix in Xcode project settings
      boring_ssl_target.build_configurations.each do |config|
        # Force remove the -G flag from all settings
        config.build_settings.each do |key, value|
          if value.is_a?(String) && value.include?('-G')
            puts "🔧 Removing -G flag from #{key}"
            config.build_settings[key] = value.gsub(/-G\s*/, '')
          end
        end
        
        # Set safer compiler flags
        config.build_settings['OTHER_CFLAGS'] = '$(inherited) -w -Wno-everything -DOPENSSL_NO_ASM'
        config.build_settings['OTHER_CPPFLAGS'] = '$(inherited) -w -Wno-everything -DOPENSSL_NO_ASM'
        config.build_settings['OTHER_SWIFT_FLAGS'] = '$(inherited) -suppress-warnings'
      end

      # Most importantly - patch the build directory where response files will be created
      derived_data_dir = `xcodebuild -showBuildSettings | grep -m 1 OBJROOT | cut -d '=' -f 2`.strip
      return if derived_data_dir.empty?

      # Save derived data path for post-build hook
      derived_data_path = Pathname.new(derived_data_dir)
      File.write("#{ENV['HOME']}/.boringssl_derived_data_path", derived_data_path.to_s)
      
      puts "✅ BoringSSL patch applied. Build path: #{derived_data_path}"
    end
  end
end

# Create a build phase script to run during Xcode build
patch_script = <<-SCRIPT
if [ -f "${HOME}/.boringssl_derived_data_path" ]; then
  DERIVED_DATA_PATH=$(cat "${HOME}/.boringssl_derived_data_path")
  echo "🔍 Looking for BoringSSL response files in: $DERIVED_DATA_PATH"
  
  # Find and patch response files during build
  find "$DERIVED_DATA_PATH" -name "*BoringSSL*.resp" -type f | while read file; do
    echo "🔧 Patching $file"
    # Remove -G flag from response file
    sed -i '' 's/-G//g' "$file"
  done
fi
SCRIPT

# Write out the script we'll use in Xcode
script_path = File.expand_path("~/fix_boringssl_script.sh")
File.write(script_path, patch_script)
FileUtils.chmod("+x", script_path)