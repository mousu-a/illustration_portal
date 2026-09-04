class Tagging < ApplicationRecord
  belongs_to :reference_archive
  belongs_to :tag
end
