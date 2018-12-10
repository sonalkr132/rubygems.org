class Mailer < ActionMailer::Base
  default_url_options[:host] = Gemcutter::HOST
  default_url_options[:protocol] = Gemcutter::PROTOCOL

  def email_reset(user)
    @user = User.find(user['id'])
    mail from: Clearance.configuration.mailer_sender,
         to: @user.unconfirmed_email,
         subject: I18n.t('mailer.confirmation_subject',
           default: 'Please confirm your email address with RubyGems.org')
  end

  def email_confirmation(user)
    @user = User.find(user['id'])
    mail from: Clearance.configuration.mailer_sender,
         to: @user.email,
         subject: I18n.t('mailer.confirmation_subject',
           default: 'Please confirm your email address with RubyGems.org')
  end

  def deletion_complete(email)
    mail from: Clearance.configuration.mailer_sender,
         to: email,
         subject: I18n.t('mailer.deletion_complete.subject')
  end

  def deletion_failed(email)
    mail from: Clearance.configuration.mailer_sender,
         to: email,
         subject: I18n.t('mailer.deletion_failed.subject')
  end

  def adoption_applicationed(adoption_application)
    adoption_application = AdoptionApplication.find(adoption_application['id'])
    adoption_application.rubygem.owners.each do |owner|
      mail from: Clearance.configuration.mailer_sender,
           to: owner.email,
           subject: I18n.t('mailer.adoption_applicationed.subject', gem: adoption_application.rubygem.name) do |format|
        format.html { render locals: { adoption_application: adoption_application, owner: owner } }
      end
    end
  end

  def adoption_application_canceled(rubygem, user)
    user = User.find(user['id'])
    rubygem = Rubygem.find(rubygem['id'])

    mail from: Clearance.configuration.mailer_sender,
         to: user.email,
         subject: I18n.t('mailer.adoption_application_canceled.subject', gem: rubygem.name) do |format|
      format.html { render locals: { rubygem: rubygem, user: user } }
    end
  end

  def adoption_application_approved(rubygem, user)
    user = User.find(user['id'])
    rubygem = Rubygem.find(rubygem['id'])

    mail from: Clearance.configuration.mailer_sender,
         to: user.email,
         subject: I18n.t('mailer.adoption_application_approved.subject', gem: rubygem.name) do |format|
      format.html { render locals: { rubygem: rubygem, user: user } }
    end
  end
end
