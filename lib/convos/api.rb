# frozen_string_literal: true

require 'uri'

module Convos
  class Api < Sinatra::Base
    set :bind, '0.0.0.0'
    set :port, Configuration.port

    set :host_authorization, {
      permitted_hosts: []
    }

    set :session_secret, Configuration.session_secret
    enable :sessions

    enable :logging if Configuration.rack_env != 'test'

    set :show_exceptions, false
    set :raise_errors, false

    not_found do
      'Not found'
    end

    error do
      status 500
      'Internal server error'
    end

    def expire_old_sessions
      Session
        .where(Session.arel_table[:created_at].lt(Time.now - Configuration.session_ttl))
        .destroy_all
      Session
        .where(Session.arel_table[:updated_at].lt(Time.now - Configuration.session_idle_timeout))
        .destroy_all
    end

    def authenticate_admin
      expire_old_sessions

      redirect '/login' unless session[:id]

      s = Session.find_by(id: session[:id])
      
      unless s
        logout
        redirect '/login'
      end

      s.touch
    end

    def logout
      Session.where(id: session[:id]).destroy_all if session[:id]
      session[:id] = nil
    end

    def validate_altcha
      altcha_payload = params[:altcha]

      return false if altcha_payload.nil? || altcha_payload.empty?
      return Altcha::V1.verify_solution(altcha_payload, Configuration.altcha_hmac_secret, true)
    end

    get '/' do
      redirect '/login'
    end

    get '/login' do
      erb :login
    end

    post '/login' do
      expire_old_sessions

      redirect '/login' if Configuration.admin_password != params[:password]
      redirect '/login' unless validate_altcha

      s = Session.create
      session[:id] = s.id

      redirect '/moderate'
    end

    get '/logout' do
      expire_old_sessions
      logout

      redirect '/login'
    end

    get '/altcha.min.js' do
      headers 'Access-Control-Allow-Origin' => Configuration.access_control_allow_origin
      content_type 'application/javascript'

      erb :altcha_min_js
    end

    get '/altcha-challenge' do
      headers 'Access-Control-Allow-Origin' => Configuration.access_control_allow_origin
      content_type :json

      options = Altcha::V1::ChallengeOptions.new(
        hmac_key: Configuration.altcha_hmac_secret,
        max_number: Configuration.altcha_challenge_cost
      )

      challenge = Altcha::V1.create_challenge(options)

      challenge.to_json
    end

    get '/moderate' do
      authenticate_admin

      erb :moderate
    end

    post '/comments/:id/approve' do
      authenticate_admin

      comment = Comment.find(params[:id])
      comment.update!(status: 'published')

      redirect '/moderate'
    end

    post '/comments/:id/reject' do
      authenticate_admin

      Comment.destroy_by(id: params[:id])

      redirect '/moderate'
    end

    get '/threads/:thread_id' do
      erb :thread
    end

    get '/threads/:thread_id/template' do
      headers 'Access-Control-Allow-Origin' => Configuration.access_control_allow_origin
      erb :thread_template
    end

    get '/convos.js' do
      headers 'Access-Control-Allow-Origin' => Configuration.access_control_allow_origin
      content_type 'application/javascript'

      erb :convos_js
    end

    post '/comments' do
      thread_id = params[:thread_id]

      user = User.create_or_find_by(username: params[:username]) do |u|
        u.password = params[:password]
      end
      
      if user.new_record?
        puts "user.password = #{params[:password]}"
        user.password = params[:password]
        user.save!
      end

      unless user.authenticate(params[:password])
        return_uri = URI.parse(params[:return_to])
        query = URI.decode_www_form(return_uri.query || '')
        query.reject! { |key, _| key == 'convos_err_msg' }
        query << ['convos_err_msg', 'Wrong password']
        return_uri.query = URI.encode_www_form(query)

        redirect return_uri.to_s
      end

      thread_root = Comment.find_by(thread_id: thread_id)

      if thread_root
        predecessor = thread_root.thread.last

        Comment.create!(user: user, body: params[:comment], predecessor: predecessor)
      else
        Comment.create!(user: user, body: params[:comment], thread_id: thread_id)
      end

      redirect params[:return_to]
    end
  end
end
