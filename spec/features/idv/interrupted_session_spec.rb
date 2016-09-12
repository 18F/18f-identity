require 'rails_helper'

feature 'Interrupted IdV session' do
  include IdvHelper

  describe 'Closing the browser while on the first form', js: true do
    before do
      allow(FeatureManagement).to receive(:proofing_requires_kbv?).and_return(false)

      sign_in_and_2fa_user
      visit idv_session_path
    end

    context 'when the alert is dismissed' do
      it 'does not display an alert when submitting the form' do
        # dismiss the alert that appears when the user closes the browser window
        # dismiss means the user clicked on "Stay on Page"
        page.driver.browser.dismiss_confirm do
          page.driver.close_window(page.driver.current_window_handle)
        end

        fill_out_idv_form_ok
        click_button 'Continue'

        expect(page).to have_content(t('idv.form.ccn'))
      end
    end
  end
end
