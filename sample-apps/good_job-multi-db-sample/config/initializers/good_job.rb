GoodJob.configure_active_record do
  connects_to database: { writing: :good_job_db, reading: :good_job_db }
end
