# frozen_string_literal: true

class PictureSetMailer < ApplicationMailer

  def image_email(email, picture_set)
    attachments.inline['animation.gif'] = File.read(File.join(picture_set.dir, picture_set.animation))
    if File.exist?(File.join(picture_set.dir, picture_set.combined))
      attachments.inline['combined.jpg'] = File.read(File.join(picture_set.dir, picture_set.combined))
    end
    I18n.with_locale(OPTS.locale) do
      mail(to: email, subject: I18n.t('picture_set_mailer.image_email.subject', name: OPTS.image_caption))
    end
  end
end
