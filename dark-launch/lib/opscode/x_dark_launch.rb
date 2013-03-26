require 'opscode/let'
require 'json'

module Opscode
  X_DARKLAUNCH_HEADER = 'HTTP_X_OPS_DARKLAUNCH'

  # Include this module to extract Darklaunch feature flags from
  # X-Ops-Darklaunch
  module XDarkLaunch
    extend Opscode::Concern
    include Opscode::Let

    included do
      let(:x_darklaunch_features)      { Hash[*x_darklaunch_features_list.flatten] } # Array to Hash

      # Ignore whitespace; delimit by ';', k1 = v1
      let(:x_darklaunch_features_list) do
        x_darklaunch_headers.gsub(/\s+/, '').
          split(';').
          map    { |x| x.split('=', 2) }.
          reject { |x| x.length != 2 }
      end

      let(:x_darklaunch_headers)       { raw_headers[Opscode::X_DARKLAUNCH_HEADER] || '' }
      let(:raw_headers)                { request.env }
    end

    def x_darklaunch_enabled?(key)
      #Merb.logger.debug "Headers: #{request.env}"
      # Valid values are '1' or '0', which must be mapped
      # to Ruby true or false
      #

      case x_darklaunch_features[key]
      when '1' then true
      when '0' then false
      else
        # Default to false for now until we decide what kind
        # of error handling we want
        false
      end
    end

    # See if an org's objects of a particular type are stored in SQL (as
    # determined by Darklaunch), or if they're still in CouchDB.
    #
    # Operationally, this is determined by a Darklaunch flag indicating
    # whether or not a particular class of Chef object is still stored
    # in CouchDB or not.  This thus makes relational storage the
    # default, and CouchDB is now the special case.  For Hosted Chef
    # deploys, then, we'll have to add the appropriate global Darklaunch
    # flags (e.g., "couchdb_roles", "couchdb_cookbooks", etc), but
    # Private Chef deploys will become progressively simpler as we roll
    # out more Erlang / SQL endpoints.
    #
    # This also means that ALL information about where data is stored is
    # determined via configuration.
    def x_data_in_sql?(type_container)
      !x_darklaunch_enabled?("couchdb_#{type_container}")
    end

    # Given the kind of Chef Object we want the ACL for, and the org,
    # determine of the objects are stored in SQL or CouchDB.
    #
    # Returns the symbol `:sql` or `:couchdb`, as appropriate
    def x_data_store_for_org_objects(type_container)
      x_data_in_sql?(type_container) ? :sql : :couchdb
    end
  end
end
