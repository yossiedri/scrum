require_dependency "project"

module Scrum
  module ProjectPatch
    def self.included(base)
      base.class_eval do

        belongs_to :product_backlog, :class_name => "Sprint"
        has_many :sprints, :dependent => :destroy, :order => "start_date ASC, name ASC",
                 :conditions => {:is_product_backlog => false}
        has_many :sprints_and_product_backlog, :class_name => "Sprint", :dependent => :destroy,
                 :order => "start_date ASC, name ASC"

        def last_sprint
          shared_sprints_and_product_backlog.sort{|a, b| a.end_date <=> b.end_date}.last
        end

        def shared_product_backlog
	        return product_backlog if product_backlog
	        return @shared_product_backlog if @shared_product_backlog
	        ancestor_project = self
	        while ancestor_project = ancestor_project.parent do
		        backlog = ancestor_project.product_backlog
		        if backlog and backlog.sharing = 'subprojects'
			        @shared_product_backlog = backlog
			        return backlog
		        end
	        end
        end

        def has_shared_product_backlog?
	        product_backlog.nil? && !shared_product_backlog.nil?
        end

        # Returns a scope of the Sprints used by the project
        def shared_sprints
	        if new_record?
		        Sprint.
			        includes(:project).
			        where("#{Project.table_name}.status <> ? AND #{Sprint.table_name}.sharing = 'system'", STATUS_ARCHIVED)
	        else
		        @shared_sprints ||= begin
                    r = root? ? self : root
                    Sprint.
                        includes(:project).
                        where(is_product_backlog: false).
                        where("#{Project.table_name}.id = #{id}" +
                              " OR (#{Project.table_name}.status <> #{Project::STATUS_ARCHIVED} AND (" +
                              " #{Sprint.table_name}.sharing = 'system'" +
                              " OR (#{Project.table_name}.lft >= #{r.lft} AND #{Project.table_name}.rgt <= #{r.rgt} AND #{Sprint.table_name}.sharing = 'tree')" +
                              " OR (#{Project.table_name}.lft < #{lft} AND #{Project.table_name}.rgt > #{rgt} AND #{Sprint.table_name}.sharing IN ('hierarchy', 'subprojects'))" +
                              " OR (#{Project.table_name}.lft > #{lft} AND #{Project.table_name}.rgt < #{rgt} AND #{Sprint.table_name}.sharing = 'hierarchy')" +
                              "))")
                end
	        end
        end

        # same as shared_sprints, plus the shared_product_backlog if there is
        # one
        def shared_sprints_and_product_backlog
	        sprints = shared_sprints
	        sprints << shared_product_backlog
	        sprints
        end

      end
    end
  end
end
