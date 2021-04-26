module Idv
  module Flows
    class RecoveryFlow < Flow::BaseFlow
      STEPS = {
        recover: Idv::Steps::RecoverStep,
        overview: Idv::Steps::OverviewStep,
        upload: Idv::Steps::UploadStep,
        send_link: Idv::Steps::SendLinkStep,
        link_sent: Idv::Steps::LinkSentStep,
        email_sent: Idv::Steps::EmailSentStep,
        document_capture: Idv::Steps::DocumentCaptureStep,
        ssn: Idv::Steps::SsnStep,
        verify: Idv::Steps::RecoverVerifyStep,
        verify_wait: Idv::Steps::RecoverVerifyWaitStep,
      }.freeze

      STEP_INDICATOR_STEPS = [
        { name: :getting_started },
        { name: :verify_id },
        { name: :verify_info },
        { name: :verify_phone_or_address },
        { name: :secure_account },
      ].freeze

      OPTIONAL_SHOW_STEPS = {
        verify_wait: Idv::Steps::RecoverVerifyWaitStepShow,
      }.freeze

      ACTIONS = {
        reset: Idv::Actions::ResetAction,
        redo_ssn: Idv::Actions::RedoSsnAction,
        verify_document: Idv::Actions::VerifyDocumentAction,
        verify_document_status: Idv::Actions::VerifyDocumentStatusAction,
      }.freeze

      attr_reader :idv_session, :session # needed to support (and satisfy) the current LOA3 flow

      def initialize(controller, session, name)
        @session = session
        @idv_session = self.class.session_idv(session)
        super(controller, STEPS, ACTIONS, session[name])
      end

      def self.session_idv(session)
        session[:idv] ||= { params: {}, step_attempts: { phone: 0 } }
      end
    end
  end
end
