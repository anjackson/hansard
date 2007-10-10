
module Hansard
end

class Hansard::HouseLordsParser < Hansard::HouseParser

  protected

    def handle_debates_child node, sitting
      if node.elem?
        name = node.name
        if name == "section"
          handle_section node, sitting.debates
        elsif (name == 'col' or name == 'image')
          handle_image_or_column name, node
        elsif (name == 'p')
          raise 'unexpected paragraph in debates section: ' + node.to_s
        else
          raise 'unknown debates section type: ' + name
        end
      elsif node.text?
        raise 'unexpected text outside of section: ' + node.to_s if node.to_s.strip.size > 0
      end
    end
end
