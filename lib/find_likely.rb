module FindLikely
  class << self
    def enable
      return if ActiveRecord::Base.respond_to?('find_likely')
      require 'find_likely/finder'
      ActiveRecord::Base.class_eval { include Finder }
    end
  end
end
