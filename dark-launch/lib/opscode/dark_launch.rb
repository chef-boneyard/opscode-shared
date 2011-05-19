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
      if @features_by_org && config_file_path &&
          File.exist?(config_file_path) &&
          @features_by_org_mtime != config_file_mtime
        Chef::Log.debug("DarkLaunch: reloading changed config file")
        @features_by_org = nil
      end

      @features_by_org ||=
        begin
          result = load_features_config
          Chef::Log.debug("DarkLaunch: @features_by_org = #{result.inspect}")
          result
        rescue
          Chef::Log.error("DarkLaunch: got exception parsing #{config_file_path}, returning false...")
          Chef::Log.error("#{$!}\n  " + $!.backtrace.join("\n  "))
          
          # if we had an error, set the @features_by_org and
          # @features_by_org_mtime to empty and *now*,
          # respectively. This way we return false for all calls until
          # the file changes.
          @features_by_org_mtime = Time.now
          Hash.new
        end

      # !! to turn falsey values into real false
      is_enabled = !!(@features_by_org[feature_name] &&
                      @features_by_org[feature_name][orgname])
      msg = ["DarkLaunch: #{feature_name}",
             is_enabled ? "IS" : "is NOT",
             "for #{orgname}"].join(" ")
      Chef::Log.debug(msg)
      is_enabled
    end

    # for testing
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
      if config_file_path
        contents = IO.read(config_file_path)
        orgs_by_feature = Chef::JSONCompat.from_json(contents)

        # check correct form for the config.
        exception_msg = "#{config_file_path} should be a hash: keys are feature name, values are arrays of orgs with that feature enabled"
        raise exception_msg unless orgs_by_feature.is_a?(Hash)
        result = Hash.new
        orgs_by_feature.keys.each do |feature_name|
          # check correct form for config, for each feature.
          feature_config = orgs_by_feature[feature_name]
          case feature_config
          when Array
            # convert array of orgnames to hash for quick lookup.
            feature_config.each do |orgname|
              result[feature_name] ||= Hash.new
              result[feature_name][orgname] = true
            end
          when TrueClass, FalseClass
            # convert to a hash with appropriate default value, in
            # this case always true or alwasy false for any (not yet
            # set key)
            result[feature_name] = Hash.new { |h, k| h[k] = feature_config }
          else
            raise exception_msg
          end
        end
          
        @features_by_org_mtime = config_file_mtime
        result
      else
        Hash.new
      end
    end

    def self.config_file_mtime
      File.mtime(config_file_path)
    end

    def self.config_file_path
      Chef::Config[:dark_launch_config_filename]
    end

  end
end
