class PictureSetMailer < ApplicationMailer

  def image_email(email, picture_set)
    attachments.inline['animation.gif'] = File.read(File.join(picture_set[:full_path], picture_set[:animation]))
    attachments.inline['combined.jpg'] = File.read(File.join(picture_set[:full_path], picture_set[:combined]))
    mail(to: email, subject: "Your Photobox picture from '#{OPTS.image_caption}'")
  end
end
