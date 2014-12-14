class ProductBacklogController < ApplicationController

  menu_item :scrum
  model_object Issue

  before_filter :find_project_by_project_id,
                :only => [:index, :sort, :new_pbi, :create_pbi, :burndown,
                          :move_pbi_to_sprint]
  before_filter :find_product_backlog,
                :only => [:index, :render_pbi, :sort, :new_pbi, :create_pbi, :burndown]
  before_filter :find_pbis, :only => [:index, :sort]
  before_filter :redirect_if_shared_product_backlog, :only => [:index, :sort]
  before_filter :check_issue_positions, :only => [:index]
  before_filter :authorize

  helper :scrum

  def index
  end

  def sort
    @pbis.each do |pbi|
      pbi.init_journal(User.current)
      pbi.position = params["pbi"].index(pbi.id.to_s) + 1
      pbi.save!
    end
    render :nothing => true
  end

  def new_pbi
    @pbi = Issue.new
    @pbi.project = @project
    @pbi.author = User.current
    @pbi.tracker = @project.trackers.find(params[:tracker_id])
    @pbi.sprint = @shared_product_backlog

    respond_to do |format|
      format.html
      format.js
    end
  end

  def create_pbi
    begin
      @continue = !(params[:create_and_continue].nil?)
      @pbi = Issue.new(params[:issue])
      @pbi.project = @project
      @pbi.author = User.current
      @pbi.sprint = @shared_product_backlog
      @pbi.save!
      @pbi.story_points = params[:issue][:story_points]
    rescue Exception => @exception
    end
    respond_to do |format|
      format.js
    end
  end

  def move_pbi_to_sprint
    issue = Issue.find params[:issue_id]
    sprint = Sprint.find params[:sprint_id]
    issue.sprint = sprint
    issue.save!
    render :nothing => true
  end

  def burndown
    @data = []
    @project.sprints.each do |sprint|
      @data << {:axis_label => sprint.name,
                :story_points => sprint.story_points,
                :pending_story_points => 0}
    end

    i = @data.length - 1
    story_points_per_sprint = 0
    while (story_points_per_sprint == 0 and i >= 0)
      story_points_per_sprint = @data[i][:story_points]
      i -= 1
    end
    story_points_per_sprint = 1 if story_points_per_sprint == 0

    # From here is the projection into the future.  Use
    # product_backlog and not shared_product_backlog, because any
    # shared_product_backlog would include issues from unrelated
    # sibling and ancestor projects, which should not be projected
    # into the time to complete the current project
    pending_story_points = @project.product_backlog ?
      @project.product_backlog.story_points : 0
    new_sprints = 1
    while pending_story_points > 0
      @data << {:axis_label => "#{l(:field_sprint)} +#{new_sprints}",
                :story_points => ((story_points_per_sprint <= pending_story_points) ? story_points_per_sprint : pending_story_points),
                :pending_story_points => 0}
      pending_story_points -= story_points_per_sprint
      new_sprints += 1
    end

    for i in 0..(@data.length - 1)
      others = @data[(i + 1)..(@data.length - 1)]
      @data[i][:pending_story_points] = @data[i][:story_points] +
        (others.blank? ? 0 : others.collect{|other| other[:story_points]}.sum)
      @data[i][:story_points_tooltip] = l(:label_pending_story_points,
                                          :pending_story_points => @data[i][:pending_story_points],
                                          :sprint => @data[i][:axis_label],
                                          :story_points => @data[i][:story_points])
    end
  end

private

  def find_product_backlog
    @product_backlog = @project.shared_product_backlog
    if @product_backlog.nil?
      render_error l(:error_no_product_backlog)
    end
  rescue
    render_404
  end

  def find_pbis
    @pbis = @project.shared_product_backlog.pbis
  rescue
    render_404
  end

  def check_issue_positions
    check_issue_position(Issue.find_all_by_sprint_id_and_position(@project.shared_product_backlog, nil))
  end

  def check_issue_position(issue)
    if issue.is_a?(Issue)
      if issue.position.nil?
        issue.reset_positions_in_list
        issue.save!
        issue.reload
      end
    elsif issue.is_a?(Array)
      issue.each do |i|
        check_issue_position(i)
      end
    else
      raise "Invalid type: #{issue.inspect}"
    end
  end

  def redirect_if_shared_product_backlog
      if !@project.product_backlog && @project.shared_product_backlog
          ancestor_with_backlog = @project.shared_product_backlog.project
          redirect_to project_product_backlog_index_path(ancestor_with_backlog)
      end
  end

end
