require File.expand_path('../../test_helper', __FILE__)

class ContactTest < ActiveSupport::TestCase
  include FotonContacts::TestHelper
  
  def setup
    setup_contact_test
  end
  
  def test_create_person
    contact = create_contact
    assert_equal 'person', contact.contact_type
    assert contact.person?
    assert !contact.company?
  end
  
  def test_create_company
    contact = create_company
    assert_equal 'company', contact.contact_type
    assert contact.company?
    assert !contact.person?
  end
  
  def test_validates_presence_of_name
    contact = Contact.new(contact_type: 'person', status: 'active')
    assert !contact.valid?
    assert contact.errors[:name].present?
  end
  
  def test_validates_contact_type
    contact = Contact.new(name: 'Test', status: 'active', contact_type: 'invalid')
    assert !contact.valid?
    assert contact.errors[:contact_type].present?
  end
  
  def test_validates_email_format
    contact = Contact.new(
      name: 'Test',
      contact_type: 'person',
      status: 'active',
      email: 'invalid-email'
    )
    assert !contact.valid?
    assert contact.errors[:email].present?
    
    contact.email = 'valid@email.com'
    assert contact.valid?
  end
  
  def test_scope_persons
    person = create_contact
    company = create_company
    
    persons = Contact.persons
    assert_includes persons, person
    assert_not_includes persons, company
  end
  
  def test_scope_companies
    person = create_contact
    company = create_company
    
    companies = Contact.companies
    assert_includes companies, company
    assert_not_includes companies, person
  end
  
  def test_scope_active
    active = create_contact
    inactive = create_contact(status: 'inactive')
    
    actives = Contact.active
    assert_includes actives, active
    assert_not_includes actives, inactive
  end
  
  def test_scope_visible
    admin = User.generate!(admin: true)
    regular_user = User.generate!
    
    public_contact = create_contact(is_private: false)
    private_contact = create_contact(is_private: true)
    my_private_contact = create_contact(is_private: true, author: regular_user)
    
    User.current = admin
    visible_to_admin = Contact.visible(admin)
    assert_includes visible_to_admin, public_contact
    assert_includes visible_to_admin, private_contact
    assert_includes visible_to_admin, my_private_contact
    
    User.current = regular_user
    visible_to_user = Contact.visible(regular_user)
    assert_includes visible_to_user, public_contact
    assert_not_includes visible_to_user, private_contact
    assert_includes visible_to_user, my_private_contact
  end
  
  def test_company_relationships
    person = create_contact
    company1 = create_company
    company2 = create_company
    
    role1 = create_contact_role(person: person, company: company1)
    role2 = create_contact_role(person: person, company: company2)
    
    assert_equal 2, person.companies.count
    assert_includes person.companies, company1
    assert_includes person.companies, company2
  end
  
  def test_employee_relationships
    company = create_company
    person1 = create_contact
    person2 = create_contact
    
    role1 = create_contact_role(person: person1, company: company)
    role2 = create_contact_role(person: person2, company: company)
    
    assert_equal 2, company.employees.count
    assert_includes company.employees, person1
    assert_includes company.employees, person2
  end
end