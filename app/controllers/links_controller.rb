class LinksController < ApplicationController
  skip_before_action :require_login, :authorize, :session_expiry, :update_activity_time, :set_taxonomy, :set_gettext_locale_db, :only => :show
  before_action :validate_root_url

  def show
    url = external_url(type: params[:type], options: params)
    redirect_to(url)
  end

  def external_url(type:, options: {})
    case type
    when 'manual'
      documentation_url(options['section'], options)
    when 'plugin_manual'
      plugin_documentation_url
    when 'feed'
      Setting['rss_url']
    when 'wiki'
      wiki_url(section: options['section'])
    when 'chat'
      'https://libera.chat'
    when 'forums'
      forum_url(options['post'])
    when 'issues'
      'https://projects.theforeman.org/projects/foreman/issues'
    when 'vmrc'
      'https://www.vmware.com/go/download-vmrc'
    end
  end

  private

  def validate_root_url
    unless params[:root_url].nil?
      root_uri = URI.parse(params[:root_url])
      unless SETTINGS[:trusted_redirect_domains].include?(root_uri.host) || SETTINGS[:trusted_redirect_domains].any? { |d| root_uri.host.end_with?(".#{d}") }
        logger.warn "Denied access to forbidden root_url: #{params[:root_url]}"
        not_found
      end
    end
  end

  def foreman_org_path(sub_path)
    "https://theforeman.org/#{sub_path}"
  end

  def documentation_url(section = "", options = {})
    root_url = options[:root_url] || foreman_org_path("manuals/#{SETTINGS[:version].short}/index.html#")
    root_url + (section || '')
  end

  def plugin_documentation_url
    name, version, section, root_url = plugin_documentation_params.values_at(:name, :version, :section, :root_url)
    path = root_url || foreman_org_path("plugins")
    path += "/#{name}"
    path += "/#{version}" unless version.nil?
    path + (section || '')
  end

  def plugin_documentation_params
    params.require(:name)
    params.permit(:version, :section, :root_url, :name, :type)
  end

  def forum_url(post_path = nil, options: {})
    root = options[:root] || 'https://community.theforeman.org'
    post_path ? "#{root}/#{post_path}" : root
  end

  def wiki_url(section: '')
    "https://projects.theforeman.org/projects/foreman/wiki/#{section}"
  end
end
