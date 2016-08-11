# This overrides the Devise mailer headers so that the recipient
# is determined based on whether or not an unconfirmed_email is present,
# as opposed to passing in the email as an argument to the job, which
# might expose it in some logs.
module Devise
  module Mailers
    module Helpers
      def headers_for(action, opts)
        headers = {
          subject: subject_for(action),
          to: recipient,
          from: mailer_sender(devise_mapping),
          reply_to: mailer_reply_to(devise_mapping),
          template_path: template_paths,
          template_name: action
        }.merge(opts)

        @email = headers[:to]
        headers
      end

      private

      def recipient
        unconfirmed_email = resource.unconfirmed_email

        unconfirmed_email.present? ? unconfirmed_email : resource.email
      end
    end
  end
end
