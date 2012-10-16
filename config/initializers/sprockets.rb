# config/initializers/sprockets.rb
module Sprockets
  module Server
    def call(env)
      start_time = Time.now.to_f
      time_elapsed = lambda { ((Time.now.to_f - start_time) * 1000).to_i }

      msg = "Served asset #{env['PATH_INFO']} -"

      # Mark session as "skipped" so no `Set-Cookie` header is set
      env['rack.session.options'] ||= {}
      env['rack.session.options'][:defer] = true
      env['rack.session.options'][:skip] = true

      # Extract the path from everything after the leading slash
      path = unescape(env['PATH_INFO'].to_s.sub(/^\//, ''))

      # URLs containing a `".."` are rejected for security reasons.
      if forbidden_request?(path)
        return forbidden_response
      end

      # Strip fingerprint
      if fingerprint = path_fingerprint(path)
        path = path.sub("-#{fingerprint}", '')
      end

      # MONKEY PATCH BEGIN

      # path is /<project-name>/resource, let's extract <project-name>
      project_name_re = /^([a-zA-Z0-9_-]+)\//
      project_name = path[project_name_re, 1]
      path.gsub! project_name_re, ""

      # remove every path under <rails-root>/..
      paths_to_keep = paths.reject do |p|
        p =~ /#{Rails.root.join("..")}/
      end
      clear_paths
      paths_to_keep.each { |p| append_path p }

      # add app/assets/<project_name>/stylesheets,
      #     app/assets/<project_name>/javascripts
      # and app/assets/<project_name>/images
      # to the load_path
      prepend_path File.join("..", project_name, "Repo", "stylesheets")
      prepend_path File.join("..", project_name, "Repo", "javascripts")
      prepend_path File.join("..", project_name, "Repo", "images")

      # MONKEY PATCH END

      # Look up the asset.
      asset = find_asset(path, :bundle => !body_only?(env))

      # `find_asset` returns nil if the asset doesn't exist
      if asset.nil?
        logger.info "#{msg} 404 Not Found (#{time_elapsed.call}ms)"

        # Return a 404 Not Found
        not_found_response

      # Check request headers `HTTP_IF_NONE_MATCH` against the asset digest
      elsif etag_match?(asset, env)
        logger.info "#{msg} 304 Not Modified (#{time_elapsed.call}ms)"

        # Return a 304 Not Modified
        not_modified_response(asset, env)

      else
        logger.info "#{msg} 200 OK (#{time_elapsed.call}ms)"

        # Return a 200 with the asset contents
        ok_response(asset, env)
      end
    rescue Exception => e
      logger.error "Error compiling asset #{path}:"
      logger.error "#{e.class.name}: #{e.message}"

      case content_type_of(path)
      when "application/javascript"
        # Re-throw JavaScript asset exceptions to the browser
        logger.info "#{msg} 500 Internal Server Error\n\n"
        return javascript_exception_response(e)
      when "text/css"
        # Display CSS asset exceptions in the browser
        logger.info "#{msg} 500 Internal Server Error\n\n"
        return css_exception_response(e)
      else
        raise
      end
    end
  end
end
