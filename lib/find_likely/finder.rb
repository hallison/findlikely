require File.dirname(__FILE__) + '/core_ext'

module FindLikely
  module Finder
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
    public
      # The method call ActiveRecord::Base::find with conditions parameters adjusted
      # for SQL LIKE condition. Is sample and useful for write simple search methods.
      # 
      # Examples:
      #
      # class Post < ActiveRecord::Base
      #   has_many :comments
      #   has_many :categories
      # end
      #
      # $ # Posts by comment body
      # $ Post.find_likely 'comments.body'  => 'works very+good', :include => :comments
      #
      # $ # Posts by category name
      # $ Post.find_likely 'categories.name' => 'plugin ruby rails', :include => :categories
      #
      # $ # Posts by title or body or comment body
      # $ Post.find_likely :title => 'find+likely', 'posts.body' => 'plugin useful works', 'comments.author' => 'hall+bati rose+camp', :include => :comments
      #
      # $ # Posts by title and body
      # $ Post.find_likely :title => 'find+likely', :body => 'plugin useful works', :clausules_logic => :and
      # > SELECT * FROM `posts` WHERE (title LIKE '%find%likely%' OR body LIKE '%plugin%' AND body LIKE '%useful%' AND body LIKE '%works%')
      def find_likely(args = {})
        # TODO: Add options for logic operators choice.
        attributes, options = filter_attributes_and_options(args)
        with_scope :find => options.merge(:conditions => attributes.to_formatted_s(:sql_like_clause)) do
          find :all
        end
      end

      # :nodoc:
      # This is a first version.
      # def find_likely(options = {}, *parameters_for_method_reference)
      #   logic_inside   = options[:logic_inside]  || :OR
      #   logic_outside  = options[:logic_outside] || :OR
      #   attributes     = options[:attributes]    || {}
      #   options.delete :logic_inside
      #   options.delete :logic_outside
      #   options.delete :attributes
      #   with_scope :find => options.merge(:conditions => attributes.to_sql_like_condition(logic_outside, logic_inside)) do
      #     find :all
      #   end
      # end

      # Create dynamically find methods by attributes.
      #
      # Example:
      # class Person < ActiveRecord::Base
      #   use_find_likely_by :name  # Person.find_by_name_likely(names)
      # end
      #
      # $ Person.find_by_name_likely 'hall rose tobi+jess'
      def use_find_likely_by(*attributes)
        # TODO: This method most be update for other params.
        unless attributes.size.zero?
          for attribute in attributes
            module_eval <<-EOD # End of definitions
              def self.find_by_#{attribute}_likely(values, options = {})
                find_likely options.merge({ :#{attribute} => values })
              end
            EOD
          end
        end
      end
    private
      # TODO: How to find constant in VALID_FIND_OPTIONS into ActiveRecord::Base
      VALID_FIND_OPTIONS    = [ :conditions, :include, :joins, :limit, :offset, :order, :select, :readonly, :group, :from, :lock ]
      #VALID_CLAUSE_OPTIONS  = [ :inside, :between, :in ]
      NOT_ALLOW_ARGS        = [ :all, :first, :last, :conditions ]

      def filter_attributes_and_options(args = {})
        attributes_params = {}
        find_options      = {}
        unless args.keys.size.zero?
          args.keys.each do |key|
            if VALID_FIND_OPTIONS.include?(key) && !NOT_ALLOW_ARGS.include?(key)
              find_options[key] = args[key]
            else
              attributes_params[key] = args[key]
            end
          end
        end
        [ attributes_params, find_options ]
      end
    end
  end
end

