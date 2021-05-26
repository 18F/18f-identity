module Encryption
  class KmsLogger
    def self.log(action, context = nil)
      output = { kms: { action: action, encryption_context: context } }
      logger.info(output.to_json)
    end

    def self.logger
      @logger ||= FeatureManagement.log_to_stdout? ? Logger.new(STDOUT) : Logger.new('log/kms.log')
    end
  end
end
