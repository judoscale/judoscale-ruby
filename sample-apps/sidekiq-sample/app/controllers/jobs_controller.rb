require 'sidekiq/api'

class JobsController < ApplicationController
  QUEUES = %w(default low high)

  def index
    @available_queues = QUEUES.dup
    @queues = Sidekiq::Stats.new.queues.sort_by { |k, _| @available_queues.index(k) }
  end

  def create
    job_params = params.require(:job).permit(:queue_name, :enqueue_count)

    queue_name = job_params[:queue_name]
    enqueue_count = job_params[:enqueue_count].to_i

    if QUEUES.include?(queue_name) && enqueue_count.between?(1, 100)
      1.upto(enqueue_count) {
        SampleJob.set(queue: queue_name).perform_async
      }

      flash[:notice] = "#{enqueue_count} #{"job".pluralize(enqueue_count)} enqueued on the #{queue_name.inspect} queue."
      redirect_to action: :index
    else
      flash[:alert] = "Please enter queue name & enqueue count."
      redirect_to action: :index
    end
  end
end
