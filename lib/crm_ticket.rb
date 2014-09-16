class CrmTicket

  attr_accessor :id, :requester_id, :submitter_id, :assignee_id, :created_at,
                :updated_at, :status, :priority, :subject, :description, :url


  def get_url
    Custom.conf['crm_ticket_url'].sub('TID', id.to_s)
  end


  class << self

    def fetch(user_id, reload=false)
      clean_ticket_cache(user_id) if reload

      Custom.cache.fetch("crmuser_tickets_for_#{user_id}") {
        fetch_tickets(user_id)
      }
    end


    def clean_ticket_cache(user_id)
      Custom.cache.delete("crmuser_tickets_for_#{user_id}")
    end


    def fetch_tickets(user_id)
      if (user = Customer.crmuser user_id)
        user.requested_tickets.map { |t|
          build_from(t) unless t.status == 'closed'
        }.compact
      else
        []
      end
    end


    def create(params)
      ticket = Customer.create_crmuser_ticket(
        submitter_id: params[:submitter_id],
        requester_id: params[:requester_id],
        description:  params[:description],
        subject:      params[:subject]
      )
      build_from(ticket) if ticket
    end


    def build_from(zt)
      new.tap { |t|
        t.id           = zt.id
        t.url          = t.get_url
        t.status       = zt.status
        t.subject      = zt.subject
        t.priority     = zt.priority
        t.created_at   = zt.created_at
        t.updated_at   = zt.updated_at
        t.description  = zt.description
        t.assignee_id  = zt.assignee_id
        t.requester_id = zt.requester_id
        t.submitter_id = zt.submitter_id
      }
    end
  end
end
