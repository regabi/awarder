module United

end

Dir[Rails.root.to_s + "/lib/united/*.rb"].each { |file| require(file) }

