class ContactIssueLink < ActiveRecord::Base
  include Redmine::SafeAttributes
  
  belongs_to :contact
  belongs_to :issue
  
  validates :contact_id, presence: true
  validates :issue_id, presence: true
  validates :contact_id, uniqueness: { scope: :issue_id }
  
  safe_attributes 'contact_id',
                 'issue_id',
                 'role',
                 'notes'
  
  def to_s
    "#{contact} (#{role})"
  end
  
  def visible?(user)
    contact.visible?(user) && issue.visible?(user)
  end
end