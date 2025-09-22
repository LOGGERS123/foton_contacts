class ContactRolesController < ApplicationController
  before_action :require_login
  before_action :find_contact_role, only: [:update, :destroy]
  before_action :authorize_global
  
  def create
    @contact_role = ContactRole.new
    @contact_role.safe_attributes = params[:contact_role]
    
    if @contact_role.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_contact_role_created)
          redirect_back_or_default contact_path(@contact_role.contact)
        }
        format.js
        format.api { render action: 'show', status: :created }
      end
    else
      respond_to do |format|
        format.html {
          flash[:error] = @contact_role.errors.full_messages.join(', ')
          redirect_back_or_default contact_path(@contact_role.contact)
        }
        format.js { render json: @contact_role.errors, status: :unprocessable_entity }
        format.api { render_validation_errors(@contact_role) }
      end
    end
  end
  
  def update
    @contact_role.safe_attributes = params[:contact_role]
    
    if @contact_role.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_contact_role_updated)
          redirect_back_or_default contact_path(@contact_role.contact)
        }
        format.js
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html {
          flash[:error] = @contact_role.errors.full_messages.join(', ')
          redirect_back_or_default contact_path(@contact_role.contact)
        }
        format.js { render json: @contact_role.errors, status: :unprocessable_entity }
        format.api { render_validation_errors(@contact_role) }
      end
    end
  end
  
  def destroy
    contact = @contact_role.contact
    @contact_role.destroy
    
    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_contact_role_deleted)
        redirect_back_or_default contact_path(contact)
      }
      format.js
      format.api { render_api_ok }
    end
  end
  
  private
  
  def find_contact_role
    @contact_role = ContactRole.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end