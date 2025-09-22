class ContactRole < ActiveRecord::Base
  include Redmine::SafeAttributes
  
  belongs_to :contact # pessoa
  belongs_to :company, class_name: 'Contact'
  
  validates :contact_id, presence: true
  validates :company_id, presence: true
  validates :position, presence: true
  validates :status, presence: true, inclusion: { in: 0..2 }
  validates :contact_id, uniqueness: { scope: [:company_id, :position] }
  validate :ensure_company_type
  validate :ensure_person_type
  
  scope :active, -> { where(status: 0) }
  scope :inactive, -> { where(status: 1) }
  scope :discontinued, -> { where(status: 2) }
  
  safe_attributes 'contact_id',
                 'company_id',
                 'position',
                 'status',
                 'start_date',
                 'end_date',
                 'notes'
  
  def active?
    status.zero?
  end
  
  def inactive?
    status == 1
  end
  
  def discontinued?
    status == 2
  end
  
  def status_name
    case status
    when 0 then 'active'
    when 1 then 'inactive'
    when 2 then 'discontinued'
    end
  end
  
  private
  
  def ensure_company_type
    if company && !company.company?
      errors.add(:company, :must_be_company)
    end
  end
  
  def ensure_person_type
    if contact && !contact.person?
      errors.add(:contact, :must_be_person)
    end
  end
end