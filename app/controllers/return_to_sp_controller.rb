class ReturnToSpController < ApplicationController
  before_action :validate_sp_exists

  def cancel
    redirect_url = sp_return_url_resolver.return_to_sp_url
    analytics.track_event(Analytics::RETURN_TO_SP_CANCEL, redirect_url: redirect_url)
    redirect_to redirect_url
  end

  def failure_to_proof
    redirect_url = sp_return_url_resolver.failure_to_proof_url
    analytics.track_event(
      Analytics::RETURN_TO_SP_FAILURE_TO_PROOF,
      redirect_url: redirect_url,
      **idv_location_params,
    )
    redirect_to redirect_url
  end

  private

  def idv_location_params
    params.permit(:step, :location).to_h.symbolize_keys
  end

  def sp_return_url_resolver
    @sp_return_url_resolver ||= SpReturnUrlResolver.new(
      service_provider: current_sp,
      oidc_state: sp_request_params[:state],
      oidc_redirect_uri: sp_request_params[:redirect_uri],
    )
  end

  def sp_request_params
    @request_params ||= begin
      if sp_request_url.present?
        UriService.params(sp_request_url)
      else
        {}
      end
    end
  end

  def sp_request_url
    sp_session[:request_url] || service_provider_request&.url
  end

  def validate_sp_exists
    redirect_to account_url if current_sp.nil?
  end
end
