SimpleForm.setup do |config|
  config.button_class = 'btn btn-primary'
  config.boolean_label_class = nil
  config.default_form_class = 'mt4'
  config.error_notification_tag = :div
  config.error_notification_class = 'mb2 p2 alert alert-oops bold center'

  config.wrappers :base do |b|
    b.use :html5
    b.use :input, class: 'field'
  end

  config.wrappers :vertical_form, tag: 'div', class: 'mb2', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: 'bold'
    b.use :input, class: 'block col-12 field'
    b.use :hint,  wrap_with: { tag: 'div' }
    b.use :error, wrap_with: { tag: 'div', class: 'mt-tiny h6 red error-message' }
  end

  config.default_wrapper = :vertical_form
end
