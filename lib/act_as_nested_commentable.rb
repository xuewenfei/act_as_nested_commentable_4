require 'active_record'

require 'awesome_nested_set'
ActiveRecord::Base.class_eval do
  include CollectiveIdea::Acts::NestedSet
end

#
unless ActiveRecord::Base.respond_to?(:acts_as_nested_set)
  ActiveRecord::Base.send(:include, CollectiveIdea::Acts::NestedSet::Base)
end


module Acts #:nodoc:
  module NestCommentable #:nodoc:
    extend ActiveSupport::Concern

    module HelperMethods
      private
      def define_role_based_inflection(role)
        send("define_role_based_inflection_#{Rails.version.first}", role)
      end

      def define_role_based_inflection_3(role)
        has_many "#{role.to_s}_comments".to_sym,
                 has_many_options(role).merge(:conditions => {role: role.to_s})
      end

      def define_role_based_inflection_4(role)
        has_many "#{role.to_s}_comments".to_sym,
                 -> { where(role: role.to_s) },
                 has_many_options(role)
      end

      def has_many_options(role)
        {:class_name => "Comment",
         :as => :commentable,
         :dependent => :destroy,
         :before_add => Proc.new { |x, c| c.role = role.to_s }
        }
      end
    end

    module ClassMethods
      include HelperMethods

      def acts_as_commentable(*args)
        comment_roles = args.to_a.flatten.compact.map(&:to_sym)

        class_attribute :comment_types
        self.comment_types = (comment_roles.blank? ? [:comments] : comment_roles)

        options = ((args.blank? or args[0].blank?) ? {} : args[0])

        if !comment_roles.blank?
          comment_roles.each do |role|
            define_role_based_inflection(role)
          end
          has_many :all_comments, {:as => :commentable, :dependent => :destroy, class_name: "Comment"}
        else
          has_many :comments, {:as => :commentable, :dependent => :destroy}
        end

        comment_types.each do |role|
          method_name = (role == :comments ? "comments" : "#{role.to_s}_comments").to_s
          class_eval %{
            def self.find_#{method_name}_for(obj)
              commentable = self.base_class.name
              Comment.find_comments_for_commentable(commentable, obj.id, "#{role.to_s}")
            end

            def self.find_#{method_name}_by_user(user)
              commentable = self.base_class.name
              Comment.where(["user_id = ? and commentable_type = ? and role = ?", user.id, commentable, "#{role.to_s}"]).order("created_at DESC")
            end

            def #{method_name}_ordered_by_submitted
              Comment.find_comments_for_commentable(self.class.name, id, "#{role.to_s}").order("created_at")
            end

            def add_#{method_name.singularize}(comment)
              comment.role = "#{role.to_s}"
              #{method_name} << comment
            end
          }
        end
        include Acts::NestCommentable::LocalInstanceMethods
      end
    end

    module LocalInstanceMethods

      # Helper method to display only root threads, no children/replies
      def root_comments
        self.comments.where(:parent_id => nil)
      end

      # Helper method to sort comments by date
      def comments_ordered_by_submitted
        Comment.where(:commentable_id => id, :commentable_type => self.class.name).order('created_at DESC')
      end

      # Helper method that defaults the submitted time.
      def add_comment(comment)
        comments << comment
      end
    end

  end
end

ActiveRecord::Base.send(:include, Acts::NestCommentable)


