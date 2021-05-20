module Idv
  module Steps
    class VerifyStep < VerifyBaseStep
      STEP_INDICATOR_STEP = :verify_info

      def call
        enqueue_job
      end

      private

      def enqueue_job
        return if flow_session[verify_step_document_capture_session_uuid_key]

        pii_from_doc[:uuid_prefix] = ServiceProvider.from_issuer(sp_session[:issuer]).app_id

        document_capture_session = create_document_capture_session(
          verify_step_document_capture_session_uuid_key,
        )

        document_capture_session.requested_at = Time.zone.now

        idv_agent.proof_resolution(
          document_capture_session,
          should_proof_state_id: should_use_aamva?(pii_from_doc),
          trace_id: amzn_trace_id,
          expired_document: expired_document,
        )
      end

      def pii_from_doc
        flow_session[:pii_from_doc]
      end

      def expired_document
        flow_session[:expired_document]
      end

      def idv_agent
        @idv_agent ||= Idv::Agent.new(pii_from_doc)
      end
    end
  end
end
