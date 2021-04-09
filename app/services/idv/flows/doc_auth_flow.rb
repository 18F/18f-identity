module Idv
  module Flows
    class DocAuthFlow < Flow::BaseFlow
      STEPS = {
        welcome: Idv::Steps::WelcomeStep,
        agreement: Idv::Steps::AgreementStep,
        upload: Idv::Steps::UploadStep,
        send_link: Idv::Steps::SendLinkStep,
        link_sent: Idv::Steps::LinkSentStep,
        email_sent: Idv::Steps::EmailSentStep,
        document_capture: Idv::Steps::DocumentCaptureStep,
        ssn: Idv::Steps::SsnStep,
        verify: Idv::Steps::VerifyStep,
        verify_wait: Idv::Steps::VerifyWaitStep,
      }.freeze

      STEP_INDICATOR_STEPS = [
        {
          slug: :getting_started,
          title: 'idv.step_indicator.getting_started',
        },
        {
          slug: :verify_id,
          title: 'idv.step_indicator.verify_id',
        },
        {
          slug: :verify_info,
          title: 'idv.step_indicator.verify_info',
        },
        {
          slug: :verify_phone_or_address,
          title: 'idv.step_indicator.verify_phone_or_address',
        },
        {
          slug: :secure_account,
          title: 'idv.step_indicator.secure_account',
        },
      ].freeze

      OPTIONAL_SHOW_STEPS = {
        verify_wait: Idv::Steps::VerifyWaitStepShow,
      }.freeze

      ACTIONS = {
        cancel_send_link: Idv::Actions::CancelSendLinkAction,
        cancel_link_sent: Idv::Actions::CancelLinkSentAction,
        reset: Idv::Actions::ResetAction,
        redo_ssn: Idv::Actions::RedoSsnAction,
        verify_document: Idv::Actions::VerifyDocumentAction,
        verify_document_status: Idv::Actions::VerifyDocumentStatusAction,
      }.freeze

      attr_reader :idv_session # this is needed to support (and satisfy) the current LOA3 flow

      def initialize(controller, session, name)
        @idv_session = self.class.session_idv(session)
        super(controller, STEPS, ACTIONS, session[name])
      end

      def self.session_idv(session)
        session[:idv] ||= { params: {}, step_attempts: { phone: 0 } }
      end
    end
  end
end
