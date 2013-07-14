ActiveSupport::Inflector.inflections do |inflect|
  inflect.singular(/(criteri)a$/i, '\1on')
  inflect.plural(/(criteri)on$/i, '\1a')
end
