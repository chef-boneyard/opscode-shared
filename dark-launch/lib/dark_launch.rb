require 'chef/json_compat'

# DarkLaunch manages features that have been "dark launched": they are
# enabled, by feature-name, for only certain organizations. Calls
# #is_feature_enabled? with orgname and feature name will return true
# if that feature should be enabled for that given organization.
module Opscode
  class DarkLaunch

    # Is a feature enabled for an organization?
    def self.is_feature_enabled?(feature_name, orgname)
      # Clear configuration if the file has changed on disk (newer or
      # older)
      if @features_by_org &&
          Chef::Config[:dark_launch_config_filename] &&
          File.exist?(Chef::Config[:dark_launch_config_filename]) &&
          @features_by_org_mtime != File.mtime(Chef::Config[:dark_launch_config_filename])
        Chef::Log.debug("DarkLaunch: reloading changed config file")
        @features_by_org = nil
      end

      @features_by_org ||=
        begin
          result = load_features_config
          Chef::Log.debug("DarkLaunch: @features_by_org = #{result.inspect}")
          result
        rescue
          Chef::Log.error("DarkLaunch: got exception parsing #{Chef::Config[:dark_launch_config_filename]}, returning false...")
          Chef::Log.error("#{$!}\n  " + $!.backtrace.join("\n  "))
          
          # if we had an error, set the @features_by_org and
          # @features_by_org_mtime to empty and *now*,
          # respectively. This way we return false for all calls until
          # the file changes.
          @features_by_org_mtime = Time.now
          Hash.new
        end
      
      if @features_by_org[feature_name] && @features_by_org[feature_name][orgname]
        Chef::Log.debug("DarkLaunch: #{feature_name} IS enabled for #{orgname}")
        true
      else
        Chef::Log.debug("DarkLaunch: #{feature_name} is not enabled for #{orgname}")
        false
      end
    end

    def self.reset_features_config
      @features_by_org = nil
      @features_by_org_mtime = nil
    end

    # Return the fully populated hash of dark launch features:
    # A hash:
    #  key = feature name
    #  value = a hash
    #    key = an organization name
    #    value = true
    private
    def self.load_features_config
      if Chef::Config[:dark_launch_config_filename]
        contents = IO.read(Chef::Config[:dark_launch_config_filename])
        orgs_by_feature = Chef::JSONCompat.from_json(contents)

        # check correct form for the config.
        exception_msg = "#{Chef::Config[:dark_launch_config_filename]} should be a hash: keys are feature name, values are arrays of orgs with that feature enabled"
        raise exception_msg unless orgs_by_feature.is_a?(Hash)

        result = Hash.new
        orgs_by_feature.keys.each do |feature_name|
          # check correct form for config, for each feature.
          raise exception_msg unless orgs_by_feature[feature_name].is_a?(Array)
          
          # convert array of orgnames to hash for quick lookup.
          orgs_by_feature[feature_name].each do |orgname|
            result[feature_name] ||= Hash.new
            result[feature_name][orgname] = true
          end
        end
          
        @features_by_org_mtime = File.mtime(Chef::Config[:dark_launch_config_filename])
        result
      else
        Hash.new
      end
    end
  end
end
