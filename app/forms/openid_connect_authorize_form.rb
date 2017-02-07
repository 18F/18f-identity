# rubocop:disable Metrics/ClassLength
class OpenidConnectAuthorizeForm
  include ActiveModel::Model
  include ActionView::Helpers::TranslationHelper

  SIMPLE_ATTRS = %i(
    client_id
    code_challenge
    code_challenge_method
    nonce
    prompt
    redirect_uri
    response_type
    state
  ).freeze

  attr_reader :acr_values,
              :scope,
              *SIMPLE_ATTRS

  validates_presence_of :acr_values,
                        :client_id,
                        :prompt,
                        :redirect_uri,
                        :scope,
                        :state

  validates_inclusion_of :response_type, in: %w(code)
  validates_inclusion_of :prompt, in: %w(select_account)
  validates_inclusion_of :code_challenge_method, in: %w(S256), if: :code_challenge

  validate :validate_acr_values
  validate :validate_client_id
  validate :validate_redirect_uri
  validate :validate_redirect_uri_matches_sp_redirect_uri
  validate :validate_scope

  def initialize(params)
    @acr_values = parse_to_values(params[:acr_values], Saml::Idp::Constants::VALID_AUTHN_CONTEXTS)
    @scope = parse_to_values(params[:scope], OpenidConnectAttributeScoper::VALID_SCOPES)
    SIMPLE_ATTRS.each do |key|
      instance_variable_set(:"@#{key}", params[key])
    end
  end

  def params # rubocop:disable Metrics/MethodLength
    {
      acr_values: acr_values.join(' '),
      client_id: client_id,
      nonce: nonce,
      prompt: prompt,
      redirect_uri: redirect_uri,
      response_type: response_type,
      scope: scope.join(' '),
      state: state,
      code_challenge: code_challenge,
      code_challenge_method: code_challenge_method,
    }.select { |_key, value| value.present? }
  end

  def submit(user, rails_session_id)
    result_uri = valid? ? success_redirect_uri(rails_session_id) : error_redirect_uri

    link_identity_to_client_id(user, rails_session_id) if valid?

    {
      success: valid?,
      redirect_uri: result_uri,
      client_id: client_id,
      errors: errors.messages,
    }
  end

  def loa3_requested?
    ial == 3
  end

  private

  def parse_to_values(param_value, possible_values)
    return [] if param_value.blank?
    param_value.split(' ').compact & possible_values
  end

  def validate_acr_values
    return if acr_values.present?
    errors.add(:acr_values, t('openid_connect.authorization.errors.no_valid_acr_values'))
  end

  def validate_client_id
    return if service_provider.valid?
    errors.add(:client_id, t('openid_connect.authorization.errors.bad_client_id'))
  end

  def validate_redirect_uri
    _uri = URI(redirect_uri)
  rescue ArgumentError, URI::InvalidURIError
    errors.add(:redirect_uri, t('openid_connect.authorization.errors.redirect_uri_invalid'))
  end

  def validate_redirect_uri_matches_sp_redirect_uri
    return if redirect_uri.blank?
    return unless service_provider.valid?
    sp_redirect_uri = service_provider.metadata[:redirect_uri]
    return if sp_redirect_uri.start_with?(redirect_uri)
    errors.add(:redirect_uri, t('openid_connect.authorization.errors.redirect_uri_no_match'))
  end

  def validate_scope
    return if scope.present?
    errors.add(:scope, t('openid_connect.authorization.errors.no_valid_scope'))
  end

  def link_identity_to_client_id(current_user, rails_session_id)
    identity_linker = IdentityLinker.new(current_user, client_id)
    identity_linker.link_identity(
      nonce: nonce,
      session_uuid: rails_session_id,
      ial: ial,
      scope: scope.join(' '),
      code_challenge: code_challenge
    )
  end

  def ial
    case acr_values.sort.max
    when Saml::Idp::Constants::LOA1_AUTHN_CONTEXT_CLASSREF
      1
    when Saml::Idp::Constants::LOA3_AUTHN_CONTEXT_CLASSREF
      3
    end
  end

  def success_redirect_uri(rails_session_id)
    URIService.add_params(redirect_uri, code: rails_session_id, state: state)
  end

  def error_redirect_uri
    URIService.add_params(
      redirect_uri,
      error: 'invalid_request',
      error_description: errors.full_messages.join(' '),
      state: state
    )
  end

  def service_provider
    @_service_provider ||= ServiceProvider.new(client_id)
  end
end
# rubocop:enable Metrics/ClassLength
