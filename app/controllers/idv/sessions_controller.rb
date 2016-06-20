class Idv::SessionsController < ApplicationController
  include IdvSession

  before_action :confirm_two_factor_authenticated

  def index
  end

  def create
    agent = Proofer::Agent.new(vendor: pick_a_vendor)
    app_vars = params.slice(:first_name, :last_name, :dob, :ssn, :address1, :address2, :city, :state, :zipcode)
                 .delete_if { |key, value| value.blank? }
    applicant = Proofer::Applicant.new(app_vars)
    set_idv_applicant(applicant)
    set_idv_vendor(agent.vendor)
    set_idv_resolution(agent.start(applicant))
    set_idv_question_number(0)
    redirect_to idv_questions_path
  end

  private

  def pick_a_vendor
    if Rails.env.test?
      :mock
    else
      available_vendors.sample
    end
  end

  def available_vendors
    @_vendors ||= ENV.fetch('PROOFING_VENDORS', '').split(/\W+/).map { |vendor| vendor.to_sym }
  end
end
