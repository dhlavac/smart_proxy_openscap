require 'smart_proxy_openscap/openscap_exception'

module Proxy::OpenSCAP
  class ForemanForwarder < Proxy::HttpRequest::ForemanRequest
    include ::Proxy::Log

    def post_arf_report(cname, policy_id, date, data, timeout)
      begin
        foreman_api_path = upload_path(cname, policy_id, date)
        json = Proxy::OpenSCAP::ArfParser.new(cname, policy_id, date).as_json(data)
        response = send_request(foreman_api_path, json, timeout)
        # Raise an HTTP error if the response is not 2xx (success).
        response.value
        JSON.parse(response.body)
      rescue Net::HTTPServerException => e
        logger.debug "Received response: #{response.code} #{response.msg}"
        logger.debug response.body
        raise ReportUploadError, e.message if response.code.to_i == 422
        raise e
      end
    end

    private

    def upload_path(cname, policy_id, date)
      "/api/v2/compliance/arf_reports/#{cname}/#{policy_id}/#{date}"
    end

    def send_request(path, body, timeout)
      # Override the parent method to set the right headers
      path = [uri.path, path].join('/') unless uri.path.empty?
      req = Net::HTTP::Post.new(URI.join(uri.to_s, path).path)
      req.add_field('Accept', 'application/json,version=2')
      req.content_type = 'application/json'
      req.body = body
      http.read_timeout = timeout if timeout
      http.request(req)
    end
  end
end
