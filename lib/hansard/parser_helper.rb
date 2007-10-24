module Hansard
end

module Hansard::ParserHelper

  def is_element? name, node
    node.elem? && node.name == name
  end

  def clean_html node
    if node
      clean_text node.inner_html
    else
      nil
    end
  end

  def clean_text text
    text.chars.gsub("\r\n","\n").to_s
  end

end
