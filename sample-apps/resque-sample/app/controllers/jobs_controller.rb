class JobsController < ApplicationController
  QUEUES = %w(default low high)

  def index
    @available_queues = QUEUES.dup
    @queues = ::Resque.queues.sort_by { |q, _| @available_queues.index(q) }.each_with_object({}) do |queue, hash|
      hash[queue] = Resque.size(queue)
    end
  end

  def create
    job_params = params.require(:job).permit(:queue_name, :enqueue_count)

    queue_name = job_params[:queue_name]
    enqueue_count = job_params[:enqueue_count].to_i

    if QUEUES.include?(queue_name) && enqueue_count.between?(1, 100)
      1.upto(enqueue_count) {
        Resque.enqueue_to(queue_name, SampleJob)
      }

      flash[:notice] = "#{enqueue_count} #{"job".pluralize(enqueue_count)} enqueued on the #{queue_name.inspect} queue."
      redirect_to action: :index
    else
      flash[:alert] = "Please enter queue name & enqueue count."
      redirect_to action: :index
    end
  end
end
