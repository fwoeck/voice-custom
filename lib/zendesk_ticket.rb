class ZendeskTicket

  attr_accessor :id, :requester_id, :submitter_id, :assignee_id, :created_at,
                :updated_at, :status, :priority, :subject, :description, :url


  def get_url
    "https://#{Custom.conf['zendesk_domain']}.zendesk.com/agent/#/tickets/#{id}"
  end


  class << self

    def fetch(uid, reload=false)
      clean_ticket_cache(uid) if reload

      Custom.cache.fetch("zendesk_tickets_for_#{uid}") {
        fetch_tickets(uid)
      }
    end


    def clean_ticket_cache(uid)
      Custom.cache.delete("zendesk_tickets_for_#{uid}")
    end


    # TODO Can we avoid fetching solved/closed tickets at all?
    #
    def fetch_tickets(uid)
      if (user = Customer.zendesk_user uid)
        user.requested_tickets.map { |t|
          build_from(t) unless ['solved', 'closed'].include?(t.status)
        }.compact
      else
        []
      end
    end


    def create(params)
      ticket = Customer.create_zendesk_ticket(
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
