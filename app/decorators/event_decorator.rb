EventDecorator = Struct.new(:event) do
  def pretty_event_type
    I18n.t("event_types.#{event.event_type}")
  end

  def happened_at
    event.created_at
  end
end
