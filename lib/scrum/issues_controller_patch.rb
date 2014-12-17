require_dependency "issues_controller"

module Scrum
  module IssuesControllerPatch
    def self.included(base)
      base.class_eval do

        after_filter :save_pending_effort, :only => [:create, :update]
        before_filter :add_default_sprint, :only => [:new, :update_form]
        # before_filter :redirect_if_wrong_project, :only => [:show]

        # redirect to the correct project if we came from the
        # shared backlog of an ancestor
        # def redirect_if_wrong_project
        #     if @project.id.to_s != params[:project_id]
        #         redirect_to project_issue_path(@issue.project.id, @issue)
        #     end
        # end

        def sprint_locked
            sprint = @issue.sprint
            params_id = params[:issue][:sprint_id].to_i
            return false if params_id == sprint.id  # no change
            return true if sprint.is_locked
            Sprint.find(params_id).is_locked
        end

        update_issue_from_params_orig = instance_method(:update_issue_from_params)
        define_method(:update_issue_from_params) do
	        return if @project.module_enabled?(:scrum) && sprint_locked
	        update_issue_from_params_orig.bind(self).call
        end

      private

        def save_pending_effort
          if @issue.is_task? and @issue.id and params[:issue] and params[:issue][:pending_effort]
            @issue.pending_effort = params[:issue][:pending_effort]
          end
        end

        def add_default_sprint
          if @issue.is_task? and @project.last_sprint and !@issue.sprint
            @issue.sprint = @project.last_sprint
          end
          if @issue.is_pbi? and @project.shared_product_backlog and !@issue.sprint
            @issue.sprint = @project.shared_product_backlog
          end
        end

      end
    end
  end
end
