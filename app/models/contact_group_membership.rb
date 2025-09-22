class ContactGroupMembership < ActiveRecord::Base
  include Redmine::SafeAttributes
  
  belongs_to :contact
  belongs_to :contact_group
  
  validates :contact_id, presence: true
  validates :contact_group_id, presence: true
  validates :contact_id, uniqueness: { scope: :contact_group_id }
  
  safe_attributes 'contact_id',
                 'contact_group_id',
                 'role',
                 'notes'
  
  def to_s
    "#{contact} (#{role})"
  end
end