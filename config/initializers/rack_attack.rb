module Rack
  class Attack
    # If the app is behind a load balancer, `ip` will return the IP of the
    # load balancer instead of the actual IP the request came from, and since
    # all requests will seem to come from the same IP, throttling will be
    # triggered right away. To make sure we have the correct IP, we use
    # ActionDispatch#remote_ip, which determines the correct IP more thoroughly
    # than Rack.
    class Request < ::Rack::Request
      def remote_ip
        @remote_ip ||= (env['action_dispatch.remote_ip'] || ip).to_s
      end
    end

    ### Configure Cache ###

    # Note: The store is only used for throttling (not blacklisting and
    # whitelisting). It must implement .increment and .write like
    # ActiveSupport::Cache::Store

    Rack::Attack.cache.store = StoreProxy::RedisStoreProxy.new(
      Redis.new(url: Figaro.env.redis_url)
    )

    ### Configure Whitelisting ###

    # Always allow requests from localhost
    # (blacklist & throttles are skipped)
    whitelist('allow from localhost') do |req|
      '127.0.0.1' == req.remote_ip || '::1' == req.remote_ip
    end unless Rails.env.production?

    ### Throttle Spammy Clients ###

    # If any single client IP is making tons of requests, then they're
    # probably malicious or a poorly-configured scraper. Either way, they
    # don't deserve to hog all of the app server's CPU. Cut them off!
    #
    # Note: If you're serving assets through rack, those requests may be
    # counted by rack-attack and this throttle may be activated too
    # quickly. If so, enable the condition to exclude them from tracking.

    # Throttle all requests by IP (60rpm)
    #
    # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
    throttle(
      'req/ip',
      limit: Figaro.env.requests_per_ip_limit.to_i,
      period: Figaro.env.requests_per_ip_period.to_i.seconds
    ) do |req|
      req.remote_ip unless req.path.starts_with?('/assets')
    end

    ### Prevent Brute-Force Login Attacks ###

    # The most common brute-force login attack is a brute-force password
    # attack where an attacker simply tries a large number of emails and
    # passwords to see if any credentials match.
    #
    # Another common method of attack is to use a swarm of computers with
    # different IPs to try brute-forcing a password for a specific account.

    # Throttle sign in attempts by IP address with an exponential backoff
    #
    # Key: "rack::attack:#{Time.now.to_i/:period}:logins/ip:#{req.ip}"
    #
    # Allows 20 requests in 8 seconds
    #        40 requests in 64 seconds
    #        ...
    #        100 requests in 0.38 days (~250 requests/day)
    (1..5).each do |level|
      throttle(
        "logins/ip/level_#{level}",
        limit: (Figaro.env.logins_per_ip_limit.to_i * level),
        period: (Figaro.env.logins_per_ip_period.to_i**level).seconds
      ) do |req|
        req.remote_ip if req.path == '/' && req.post?
      end
    end

    ### Custom Throttle Response ###

    # By default, Rack::Attack returns an HTTP 429 for throttled responses,
    # which is just fine.
    #
    # If you want to return 503 so that the attacker might be fooled into
    # believing that they've successfully broken your app (or you just want to
    # customize the response), then uncomment these lines.
    self.throttled_response = lambda do |_env|
      [
        429, # status
        { 'Content-Type' => 'text/html' }, # headers
        [::File.read('public/429.html')] # body
      ]
    end
  end
end

ActiveSupport::Notifications.subscribe('rack.attack') do |_name, _start, _finish, _request_id, req|
  Rails.logger.warn(
    "#{req.env['rack.attack.matched']} throttle occurred for " \
    "#{req.env['rack.attack.match_discriminator']}"
  )
end
