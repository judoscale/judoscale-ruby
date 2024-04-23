class JobsController < ApplicationController
  QUEUES = %w[default low high]

  def index
    @available_queues = QUEUES.dup
    @queues = ::SolidQueue::ReadyExecution.group(:queue_name).count
  end

  def create
    job_params = params.require(:job).permit(:queue_name, :enqueue_count)

    queue_name = job_params[:queue_name]
    enqueue_count = job_params[:enqueue_count].to_i

    if QUEUES.include?(queue_name) && enqueue_count.between?(1, 100)
      1.upto(enqueue_count) {
        SampleJob.set(queue: queue_name).perform_later
      }

      flash[:notice] = "#{enqueue_count} #{"job".pluralize(enqueue_count)} enqueued on the #{queue_name.inspect} queue."
    else
      flash[:alert] = "Please enter queue name & enqueue count."
    end
    redirect_to action: :index
  end
end
