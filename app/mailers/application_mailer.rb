class ApplicationMailer < ActionMailer::Base
  default from: OPTS.mail_from
  layout 'mailer'
end
