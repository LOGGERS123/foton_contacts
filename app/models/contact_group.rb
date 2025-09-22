class ContactGroup < ActiveRecord::Base
  include Redmine::SafeAttributes
  
  belongs_to :author, class_name: 'User'
  belongs_to :project, optional: true
  
  has_many :memberships, class_name: 'ContactGroupMembership', dependent: :destroy
  has_many :contacts, through: :memberships
  
  validates :name, presence: true, uniqueness: { scope: :project_id }
  
  scope :system_groups, -> { where(is_system: true) }
  scope :user_groups, -> { where(is_system: false) }
  scope :visible, ->(user) do
    if user&.admin?
      all
    else
      where(is_private: false).or(where(author_id: user&.id))
    end
  end
  
  safe_attributes 'name',
                 'description',
                 'is_private',
                 'project_id'
  
  def visible?(user)
    return true if user&.admin?
    !is_private || author_id == user&.id
  end
  
  def to_s
    name
  end
  
  def css_classes
    classes = ['contact-group']
    classes << 'system' if is_system?
    classes << 'private' if is_private?
    classes.join(' ')
  end
  
  def deletable?
    !is_system?
  end
end