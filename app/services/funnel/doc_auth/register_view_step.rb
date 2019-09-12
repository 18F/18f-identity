module Funnel
  module DocAuth
    class RegisterViewStep
      def self.call(doc_auth_log, token, _success)
        doc_auth_log["#{token}_view_at"] = Time.zone.now
        doc_auth_log["#{token}_view_count"] += 1
        doc_auth_log.save
      end
    end
  end
end
