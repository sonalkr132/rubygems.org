module EmailHelpers
  def last_email
    Delayed::Worker.new.work_off
    ActionMailer::Base.deliveries.last
  end

  def last_email_link
    link = /href="([^"]*)"/.match(last_email.to_s)
    link[1]
  end
end
