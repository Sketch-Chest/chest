module Chest
  def sanitize_name(name)
    name.gsub(/[\s\/]/, '-')
  end
end
