class PictureSetMailer < ApplicationMailer

  def image_email(email, picture_set)
    attachments.inline['animation.gif'] = File.read(File.join(picture_set[:full_path], picture_set[:animation]))
    if File.exist?(File.join(picture_set[:full_path], picture_set[:combined]))
      attachments.inline['combined.jpg'] = File.read(File.join(picture_set[:full_path], picture_set[:combined]))
    end
    mail(to: email, subject: "Your Photobox picture from '#{OPTS.image_caption}'")
  end
end
