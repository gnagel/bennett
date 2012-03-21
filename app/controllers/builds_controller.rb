class BuildsController < ApplicationController
  skip_before_filter :authenticate, :only => :create

  # POST /builds
  # POST /builds.json
  def create
    @project = Project.find(params[:project_id])
    @build = @project.builds.new(params[:build])
    @manual = params[:manual]

    respond_to do |format|
      if @manual || @build.new_activity?
        if @build.save
          Resque.enqueue(CommitsFetcher, @build.id)
          format.html { redirect_to @project, notice: 'Build successfully added to queue.' }
          format.json { render json: @build, status: :created, location: @build }
        else
          format.html { redirect_to @project, notice: 'Error adding build.' }
          format.json { render json: @build.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def destroy
    @build = Build.find(params[:id])
    @build.delete_jobs_in_queues
    if @build.destroy
      flash[:notice] = "Build successfully deleted."
      redirect_to project_path(@build.project)
    else
      flash[:error] = "Error deleting build."
      redirect_to project_path(@build.project)
    end
  end
end
