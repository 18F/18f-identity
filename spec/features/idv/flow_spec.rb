require 'rails_helper'

feature 'IdV session' do
  include IdvHelper

  let(:user_password) { Features::SessionHelper::VALID_PASSWORD }
  let(:max_attempts_less_one) { Idv::Attempter.idv_max_attempts - 1 }

  context 'landing page' do
    before do
      sign_in_and_2fa_user
      visit verify_path
    end

    scenario 'decline to verify identity' do
      click_link t('links.cancel')

      expect(page).to have_content(t('idv.titles.cancel'))
    end

    scenario 'proceed to verify identity' do
      click_link 'Yes'

      expect(page).to have_content(t('idv.titles.session.basic'))
    end
  end

  context 'verification session' do
    scenario 'normal flow' do
      user = sign_in_and_2fa_user

      visit verify_session_path

      fill_out_idv_form_ok
      click_button t('forms.buttons.continue')
      expect(page).to have_content(t('idv.form.ccn'))

      fill_out_financial_form_ok
      click_button t('forms.buttons.continue')
      fill_out_phone_form_ok(user.phone)
      click_button t('forms.buttons.continue')
      fill_in :user_password, with: user_password
      click_button t('forms.buttons.submit.default')

      expect(current_url).to eq verify_confirmations_url
      expect(page).to have_content(t('headings.recovery_code'))
      click_acknowledge_recovery_code

      expect(current_url).to eq(profile_url)
      expect(page).to have_content('Some One')
      expect(page).to have_content('123 Main St')
      expect(user.reload.active_profile).to be_a(Profile)
    end

    scenario 'allows 3 attempts in 24 hours' do
      user = sign_in_and_2fa_user

      max_attempts_less_one.times do
        visit verify_session_path
        complete_idv_profile_fail

        expect(current_path).to eq verify_session_path
      end

      user.reload
      expect(user.idv_attempted_at).to_not be_nil

      visit destroy_user_session_url
      sign_in_and_2fa_user(user)

      visit verify_session_path
      complete_idv_profile_fail

      expect(page).to have_content(t('idv.titles.hardfail'))

      visit verify_session_path

      expect(page).to have_content(t('idv.errors.hardfail'))
      expect(current_url).to eq verify_fail_url

      user.reload
      expect(user.idv_attempted_at).to_not be_nil
    end

    scenario 'finance step redirects to fail after max attempts' do
      sign_in_and_2fa_user
      visit verify_session_path
      fill_out_idv_form_ok
      click_idv_continue

      max_attempts_less_one.times do
        fill_out_financial_form_fail
        click_idv_continue

        expect(current_path).to eq verify_finance_path
      end

      fill_out_financial_form_fail
      click_idv_continue
      expect(current_path).to eq verify_fail_path
    end

    scenario 'phone step redirects to fail after max attempts' do
      sign_in_and_2fa_user
      visit verify_session_path
      fill_out_idv_form_ok
      click_idv_continue
      fill_out_financial_form_ok
      click_idv_continue

      max_attempts_less_one.times do
        fill_out_phone_form_fail
        click_idv_continue

        expect(current_path).to eq verify_phone_path
      end

      fill_out_phone_form_fail
      click_idv_continue
      expect(current_path).to eq verify_fail_path
    end

    scenario 'successful steps are not re-entrant, but are sticky on failure', js: true do
      _user = sign_in_and_2fa_user

      visit verify_session_path

      first_ssn_value = '666-66-6666'
      second_ssn_value = '666-66-1234'
      first_ccn_value = '00000000'
      second_ccn_value = '12345678'
      mortgage_value = '00000000'
      good_phone_value = '415-555-9999'
      good_phone_formatted = '+1 (415) 555-9999'
      bad_phone_formatted = '+1 (555) 555-5555'

      # we start with blank form
      expect(page).to_not have_selector("input[value='#{first_ssn_value}']")

      fill_out_idv_form_fail
      click_idv_continue

      # failure reloads the form
      expect(current_path).to eq verify_session_path

      fill_out_idv_form_ok
      click_idv_continue

      # success advances to next step
      expect(current_path).to eq verify_finance_path

      # we start with blank form
      expect(page).to_not have_selector("input[value='#{first_ccn_value}']")

      fill_in :idv_finance_form_ccn, with: first_ccn_value
      click_idv_continue

      # failure reloads the form
      expect(current_path).to eq verify_finance_path

      # can't go "back" to a successful step
      visit verify_session_path

      expect(current_path).to eq verify_finance_path

      # re-entering a failed step is sticky
      expect(page).to have_content(t('idv.form.ccn'))
      expect(page).to have_selector("input[value='#{first_ccn_value}']")

      # try again, but with different finance type
      click_link t('idv.form.use_financial_account')

      expect(current_path).to eq verify_finance_other_path

      select t('idv.form.mortgage'), from: 'idv_finance_form_finance_type'
      fill_in :idv_finance_form_mortgage, with: mortgage_value
      click_idv_continue

      # failure reloads the same sticky form (different path)
      expect(current_path).to eq verify_finance_path
      expect(page).to have_selector("input[value='#{mortgage_value}']")

      # try again with CCN
      click_link t('idv.form.use_ccn')
      fill_in :idv_finance_form_ccn, with: second_ccn_value
      click_idv_continue

      # success advances to next step
      expect(current_path).to eq verify_phone_path

      # we start with blank form
      expect(page).to_not have_selector("input[value='#{bad_phone_formatted}']")

      fill_out_phone_form_fail
      click_idv_continue

      # failure reloads the same sticky form
      expect(current_path).to eq verify_phone_path
      expect(page).to have_selector("input[value='#{bad_phone_formatted}']")

      fill_out_phone_form_ok(good_phone_value)
      click_idv_continue

      # success advances to next step
      expect(page).to have_content(t('idv.titles.review'))
      expect(page).to have_content(second_ssn_value)
      expect(page).to_not have_content(first_ssn_value)
      expect(page).to have_content(second_ccn_value)
      expect(page).to_not have_content(mortgage_value)
      expect(page).to_not have_content(first_ccn_value)
      expect(page).to have_content(good_phone_formatted)
      expect(page).to_not have_content(bad_phone_formatted)
    end

    scenario 'clicking finance option changes input label', js: true do
      _user = sign_in_and_2fa_user

      visit verify_session_path

      fill_out_idv_form_ok
      click_button t('forms.buttons.continue')

      expect(page).to_not have_css('.js-finance-wrapper', text: t('idv.form.mortgage'))

      click_link t('idv.form.use_financial_account')

      expect(page).to_not have_content(t('idv.form.ccn'))
      expect(page).to have_css('input[type=submit][disabled]')
      expect(page).to have_css('.js-finance-wrapper', text: t('idv.form.auto_loan'), visible: false)

      select t('idv.form.auto_loan'), from: 'idv_finance_form_finance_type'

      expect(page).to have_css('.js-finance-wrapper', text: t('idv.form.auto_loan'), visible: true)
    end

    scenario 'enters invalid finance value', js: true do
      _user = sign_in_and_2fa_user
      visit verify_session_path
      fill_out_idv_form_ok
      click_button t('forms.buttons.continue')
      click_link t('idv.form.use_financial_account')

      select t('idv.form.mortgage'), from: 'idv_finance_form_finance_type'
      short_value = '1' * (FormFinanceValidator::VALID_MINIMUM_LENGTH - 1)
      fill_in :idv_finance_form_mortgage, with: short_value
      click_button t('forms.buttons.continue')

      expect(page).to have_content(
        t(
          'idv.errors.finance_number_length',
          minimum: FormFinanceValidator::VALID_MINIMUM_LENGTH,
          maximum: FormFinanceValidator::VALID_MAXIMUM_LENGTH
        )
      )
    end

    scenario 'credit card field only allows numbers', js: true do
      _user = sign_in_and_2fa_user

      visit verify_session_path

      fill_out_idv_form_ok
      click_button 'Continue'

      find('#idv_finance_form_ccn').native.send_keys('abcd1234')

      expect(find('#idv_finance_form_ccn').value).to eq '1234'
    end

    context 'Idv phone and user phone are different' do
      it 'prompts to confirm phone' do
        user = create(
          :user, :signed_up,
          phone: '+1 (416) 555-0190',
          password: Features::SessionHelper::VALID_PASSWORD
        )
        sign_in_and_2fa_user(user)
        visit verify_session_path

        complete_idv_profile_with_phone('555-555-0000')

        expect(page).to have_link t('forms.two_factor.try_again'), href: verify_phone_path

        enter_correct_otp_code_for_user(user)
        click_acknowledge_recovery_code

        expect(current_path).to eq profile_path
      end
    end

    context 'recovery codes information and actions' do
      before do
        recovery_code = 'a1b2c3d4e5f6g7h8'

        @user = sign_in_and_2fa_user
        visit verify_session_path

        allow(SecureRandom).to receive(:hex).with(8).and_return(recovery_code)
        complete_idv_profile_ok(@user)
      end

      scenario 'recovery code presented on success' do
        expect(page).to have_content(t('headings.recovery_code'))
      end

      it_behaves_like 'recovery code page'
    end
  end

  def complete_idv_profile_fail
    fill_out_idv_form_fail
    click_button 'Continue'
  end

  def complete_idv_profile_with_phone(phone)
    fill_out_idv_form_ok
    click_button t('forms.buttons.continue')
    fill_out_financial_form_ok
    click_button t('forms.buttons.continue')
    fill_out_phone_form_ok(phone)
    click_button t('forms.buttons.continue')
    fill_in :user_password, with: user_password
    click_submit_default
    # choose default SMS delivery method for confirming this new number
    click_submit_default
  end
end
