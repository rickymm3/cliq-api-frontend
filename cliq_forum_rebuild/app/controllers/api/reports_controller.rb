class Api::ReportsController < Api::BaseController
  before_action :authenticate_api_user!

  def index
    # Only allow moderators/admins to index
    # We should add authorization here later
    reports = Report.all
    render json: reports
  end

  def show
    report = Report.find(params[:id])
    render json: report
  end

  def create
    report = Report.new(report_params)
    report.reporter_id = @current_user.id
    if report.save
      render json: report, status: :created
    else
      render json: report.errors, status: :unprocessable_entity
    end
  end

  def update
    report = Report.find(params[:id])
    if report.update(report_params)
      render json: report
    else
      render json: report.errors, status: :unprocessable_entity
    end
  end

  def destroy
    report = Report.find(params[:id])
    report.destroy
    head :no_content
  end

  private

  def report_params
    params.require(:report).permit(:cliq_id, :reportable_type, :reportable_id, :reason, :status)
  end
end
