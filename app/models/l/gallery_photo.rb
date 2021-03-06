module L
  # Model reprezentujący zdjęcie należące do galerii.
  #
  # * *Atrybuty*:
  #
  #   - +photo+ - załącznik Paperclip, style zdjęcia:
  #
  #     * +:big+ - 800x600
  #     * +:medium+ - 300x300
  #     * +:small_crop+ - 120x120, obcięte
  #     * +:small+ - 120x120
  #     * +:thumb+ - 100x100
  #     * +:mobile_thumb+ - 80x80, obcięte
  #
  # * *Relacje*:
  #
  #   - <tt>belongs_to :gallery</tt> - galeria do której należy zdjęcie
  #
  class GalleryPhoto < ActiveRecord::Base
    include ::PublicActivity::Common
    acts_as_paranoid

    attr_accessible :gallery_id, :photo

    belongs_to :gallery
    has_attached_file :photo,
      styles: {
        big: "800x600>",
        medium: "300x300>",
        small_crop: "120x120",
        small: "120x120>",
        thumb: "100x100>",
        mobile_thumb: "80x80#" },
      path: ":rails_root/public/system/gallery_photos/:id/:style/:filename",
      url: "/system/gallery_photos/:id/:style/:filename",
      preserve_files: true

    validates :gallery_id, presence: true
    validates_attachment :photo, presence: true, content_type: {content_type: /^image/}
  end

end
