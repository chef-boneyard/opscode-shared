require 'sequel'

module Opscode
  module HelpspotSSO
    DATABASE_URI = nil

    def helpspot_db
      @helpspot_db ||= Sequel.connect(DATABASE_URI)
    end

    def create_helpspot_user(email)
      return 0 unless DATABASE_URI
      portal_users = helpspot_db[:HS_Portal_Login]
      portal_users.on_duplicate_key_update(:sPassword).insert(:sEmail => email, :sPassword => '')
      portal_users.select(:xLogin).where(:sEmail => email).first
    end

    def create_helpspot_session(user)
      #login_username, login_sEmail, login_ip, and login_xLogin
      email = user.email
      session[:login_username] = user.responds_to?(:unique_name) ? user.unique_name : user.username
      session[:login_sEmail] = email
      session[:login_xLogin] = create_helpspot_user(email)
      session[:login_ip] = request.remote_ip
    end

    def remove_helpspot_session
      session.delete(:login_username)
      session.delete(:login_sEmail)
      session.delete(:login_xLogin)
      session.delete(:login_ip)
    end
  end
end
