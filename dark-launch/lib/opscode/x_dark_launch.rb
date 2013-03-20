require 'rlet'
require 'json'

module Opscode
  X_DARKLAUNCH_HEADER = 'HTTP_X_OPS_DARKLAUNCH'

  # Include this module to extract Darklaunch feature flags from
  # X-Ops-Darklaunch
  module XDarkLaunch
    extend Concern
    include Let

    included do
      let(:x_darklaunch_features) { JSON.parse(x_darklaunch_headers) }
      let(:x_darklaunch_headers)  { raw_headers[Opscode::X_DARKLAUNCH_HEADER] }
      let(:raw_headers)           { request.env }
    end

    def x_darklaunch_enabled?(key)
      #Merb.logger.debug "Headers: #{request.env}"
      x_darklaunch_features[key]
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
