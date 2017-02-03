class Customer < ActiveRecord::Base
    
    belongs_to :user
    
    has_many :contacts, dependent: :destroy
    has_many :notes
    
	validates :phone, :street, :city, :state, :country, :postal_code, :decription, presence: true

    track_who_does_it

    #constants
    TYPE = %w(Contractor Sales_Customer)

	def self.search(params)
	  search = all
	  search = search.where("customers.id = ?",params[:code].gsub(/\D/,'')) if params[:code].present?
	  if params[:name].present?
	    name = params[:name].downcase
	    search = search.joins(:user)
	      .where("(((lower(users.first_name) || ' ' || lower(users.last_name)) LIKE ?) "\
	             'OR (lower(users.first_name) LIKE ?) OR (lower(users.last_name) LIKE ?))',\
	             "%#{name}%", "%#{name}%", "%#{name}%")
	  end
	  search = search.where('customers.phone = ?',params[:phone]) if params[:phone].present?
	  search = search.where('customers.country = ?',params[:country]) if params[:country].present?
	  search = search.where('customers.c_type IN (?)',params[:c_type]) if params[:c_type].present?
	  search = search.where('customers.created_by_id = ?',params[:created_by_id]) if params[:created_by_id].present?
	  search = search.where('DATE(customers.created_at) = ?', params[:created_at].to_date) if params[:created_at].present?
	  return search
	end

	def self.sales_customers(current_user)
		where("customers.sales_user_id = ?",current_user.id)
	end

    def get_json_customer_show
        customer_since = self.customer_since.present? ? self.customer_since.strftime('%d %B, %Y') : self.customer_since 
        as_json(only: [:id,:phone,:c_type,:street,:city,:state,:country,:postal_code,
        	:decription,:discount_percent,:credit_limit,:tax_reference,:payment_terms,
        	:customer_currency])
        .merge({
        	code:"CUS#{self.id.to_s.rjust(4, '0')}",
        	name:self.user.full_name,
        	email:self.user.email,
        	created_at:self.created_at.strftime('%d %B, %Y'),
        	created_by:self.creator.try(:full_name),
        	updated_at:self.updated_at.strftime('%d %B, %Y'),
        	updated_by:self.updater.try(:full_name),
        	notes:Note.get_json_notes(false,self.notes),
            contacts:Contact.get_json_contacts(false,self.contacts),
            customer_since: customer_since,
        	})
    end  

    def get_json_customer_index
        as_json(only: [:id,:phone,:c_type,:country])
        .merge({name:self.user.full_name,
        	created_at:self.created_at.strftime('%d %B, %Y'),
        	created_by:self.creator.try(:full_name),
        	})
    end 

    def self.get_json_customers
        customers_list =[]
        Customer.all.each do |customer|
          customers_list << customer.get_json_customer_index
        end
        return customers_list
    end

    def get_json_customer_edit
        created_at = self.created_at.present? ? self.created_at.strftime('%d %B, %Y') : self.created_at
        customer_since = self.customer_since.present? ? self.customer_since.strftime('%d %B, %Y') : self.customer_since 
        as_json(only: [])
        .merge({
            code:"CUS#{self.id.to_s.rjust(4, '0')}",
            id: self.user.id,
            email: self.user.email,
            first_name: self.user.first_name,
            last_name: self.user.last_name,
            customer_attributes:{
                id: self.id,
                phone: self.phone,
                c_type: self.c_type,
                street: self.street,
                city: self.city,
                state: self.state,
                country: self.country,
                postal_code: self.postal_code,
                decription: self.decription,
                discount_percent: self.discount_percent,
                credit_limit: self.credit_limit,
                tax_reference: self.tax_reference,
                payment_terms: self.payment_terms,
                customer_currency: self.customer_currency,
                created_at: created_at,
                customer_since:self.customer_since,
            }
        })
    end 
end
