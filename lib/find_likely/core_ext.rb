String.class_eval do
  # Create a formatted string values. Has been two params:
  #
  # * +:sql_like_params+, convert string to array with SQL LIKE params,
  #   replacing plus character to percent.
  # * +:sql_like_clause+, convert string to other string with SQL LIKE clause
  #   ('<attribute> LIKE ?)' join by logic delimiter, in the case of more one
  #   clausule.
  #
  # Example:
  #   'hall+bati rose+camp'.to_formatted_s(:sql_like_params)
  #   > ["%hall%bati%", "%rose%camp%"]
  #
  #   'hall, rose, tobi+jess'.to_formatted_s(:sql_like_params)
  #   > ["%hall%", "%rose%", "%tobi%jess%"]
  #
  #   "name".to_formatted_s(:sql_like_params)
  #   > "LOWER(name) LIKE LOWER(?)"
  #
  #   "name".to_formatted_s(:sql_like_params, 2)
  #   > "LOWER(name) LIKE LOWER(?) OR LOWER(name) LIKE LOWER(?)"
  #
  #   "full name".to_formatted_s(:sql_like_params, 3, :AND)
  #   > "LOWER(full_name) LIKE LOWER(?) AND LOWER(full_name) LIKE LOWER(?) AND LOWER(full_name) LIKE LOWER(?)"
  def to_formatted_s(format = nil, repeat_times = 1, logic_operator = :or)
    case format
    when :sql_like_params
      (self.split(/[,\ ]/).collect { |filter| "%#{filter.gsub(/[\*\+]/,'%')}%" })
    when :sql_like_clause
      (Array.new(repeat_times) { "LOWER(#{self.gsub(/[\,\+ ]/,'_')}) LIKE LOWER(?)" }).join(" #{logic_operator.to_s.upcase} ")
    else
      nil
    end
  end

  # Convert to range, spliting by two dots.
  #
  # Example:
  #
  #   '1..5'.to_sql_between_params
  #   > 1..5
  #
  #   '1 .. 5 .. 8'.to_sql_between_params
  #   > ["1", "8"]
  #
  #   '1 ... ..3 ... 4. .. .5'.to_sql_between_params
  #   > ["1", "5"]
  def to_r
    array = self.gsub('..',',').gsub(/[\. ]/,'').split(',').sort
    Range.new(array.first, array.last) if array
  end

  # XXX: It's not works.
  # Convert to array spliting by commas.
  #
  # Examples:
  #
  #   $ '1, 2, 3, 4'.to_a
  #   > ['1', '2', '3', '4']
  #
  #   $ 'abc, def, ghi'.to_a
  #   > ['abc', 'def', 'ghi']
  #def to_a(delimiter = ',')
  #  (self.match(Regexp.new(".+#{delimiter}.+")))? self.gsub(/ /,'').split(delimiter).compact.uniq : super
  #end
end

# Convert array to hash.
Array.class_eval do
  def to_h(&block)
    Hash[*self.collect { |key| [key, block.call(key)] }.flatten]
  end
  
 #def to_h
 #  attribute = nil
 #  hash      = {}
 #  if array.class == Array
 #    attribute = array.first
 #    hash      = { attribute => (array - [array.first]).join(" ") }
 #  end
 #end

  # Convert, sorting and creating, to new range.
  #
  # Examples:
  #
  # $ [1, 5, 4, 7, 2, 8].to_r
  # > 1..7
  #
  # $ ['z', 'd', 'a', 'x', 'b'].to_r
  # > 'a'..'z'
  #
  # $ [Tue, 01 Jan 2008, Thu, 01 Mar 2007, Wed, 01 Aug 2007, Mon, 01 Jan 2007, Thu, 01 Jan 2009].to_r
  # > Mon, 01 Jan 2007..Thu, 01 Jan 2009
  def to_r
    array = self.sort
    Range.new(array.first, array.last)
  end
end

Hash.class_eval do
  # Create an array of strings supported with conditions parameters into
  # method ActiveRecord::Base#find.
  #
  # Example:
  #
  #   attributes = { :name => "hall rose tobi+jess", :role => "dad mom son" }
  #   attributes.to_sql_like_condition
  #   > ["role LIKE ? OR role LIKE ? OR role LIKE ? OR name LIKE ? OR name LIKE ? OR name LIKE ?", "%dad%", "%mom%", "%son%", "%hall%", "%rose%", "%tobi%jess%"]
  #
  #   attributes = { :permalink => "plugin-find-likely", "comment.body" => "great works good+job", 'page.title' => 'plugin' }
  #   attributes.to_sql_like_condition(:AND)
  #   > ["permalink LIKE ? AND page.title LIKE ? AND comment.body LIKE ? OR comment.body LIKE ? OR comment.body LIKE ?", "%plugin-find-likely%", "%plugin%", "%great%", "%works%", "%good%job%"]
  def to_formatted_s(format = :sql_like_clause, operator_for_clauses = :or, operator_for_values = :or)
    condition_values, condition_clauses = [], []
    self.each do |attribute, values|
      params_values      = values.to_s.to_formatted_s(:sql_like_params)
      condition_values  += params_values
      condition_clauses += attribute.to_s.to_formatted_s(:sql_like_clause, params_values.size, operator_for_values).to_a
    end
    (condition_clauses).join(" #{operator_for_clauses.to_s.upcase} ").to_a + condition_values
  end
end

