
# Monkey-patches JSON gem to be replaced by OJ
Oj.mimic_JSON


# In case a Gem uses MultiJSON:
MultiJson.use(:oj)


# ActiveSupport monkey patches to_json() to calls ActiveSupport::JSON.encode
# We cancel that monkey patch and call directly into Oj
# This will ignore the to_json() options that ActiveSupport introduces
# Also, Actionpack renders json responses by calling to_json().
[Object, Array, FalseClass, Float, Hash, Integer, NilClass, String, TrueClass].each do |klass|
  klass.class_eval do
    def to_json(opts = nil)
      Oj.dump(self, opts)
    end
  end
end
