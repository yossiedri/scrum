require_dependency "issue_status"

module Scrum
  module IssueStatusPatch
    def self.included(base)
      base.class_eval do

        def self.task_statuses
          IssueStatus.find(Scrum::Setting.task_status_ids, :order => "position ASC")
        end

        # Returns an array of all statuses the given role can switch to this status
        def find_old_statuses_allowed_from(roles, tracker, author=false, assignee=false)
	        if roles.present? && tracker
		        conditions = "(author = :false AND assignee = :false)"
		        conditions << " OR author = :true" if author
		        conditions << " OR assignee = :true" if assignee

		        WorkflowTransition.where(new_status_id: self).
			        includes(:old_status).
			        where(["role_id IN (:role_ids) AND tracker_id = :tracker_id AND (#{conditions})",
			               {:role_ids => roles.collect(&:id), :tracker_id => tracker.id, :true => true, :false => false}
			              ]).all.
			        map(&:old_status).compact.sort
	        else
		        []
	        end
        end

      end
    end
  end
end
