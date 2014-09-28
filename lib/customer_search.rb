class CustomerSearch

  attr_accessor :c_opts, :c_query, :h_opts, :h_query, :customer_ids, :history


  def self.search(opts)
    new(opts).search
  end


  def initialize(opts)
    size    = opts.fetch(:size, 100)
    @c_opts = {q: opts.fetch(:c, ""), size: size}
    @h_opts = {q: opts.fetch(:h, ""), size: size}

    @c_query = c_opts[:q].size > 0
    @h_query = h_opts[:q].size > 0
  end


  def search
    @customer_ids = find_customer_ids
    @history      = find_history_entries
    aggregate_customers
  end


  def find_customer_ids
    return [] unless c_query
    Customer.es.search(c_opts).results.map(&:id)
  rescue Elasticsearch::Transport::Transport::Errors::BadRequest
    []
  end


  def find_history_entries
    return {} unless h_query
    HistoryEntry.es.search(h_opts).results
                .group_by { |he| he.customer_id }
  rescue Elasticsearch::Transport::Transport::Errors::BadRequest
    {}
  end


  def aggregate_customers
    filtered_customers.each_with_object([]) { |cust, result|
      assemble_entries_from(history, cust) if h_query
      result << cust
    }
  end


  def filtered_customers
    keys = c_query ? customer_ids : (h_query ? history.keys : [])
    keys = h_query ? keys.map(&:to_s) & history.keys : keys
    Customer.where(:_id.in => keys).without('history_entries')
  end


  def assemble_entries_from(history, cust)
    history[cust.id.to_s].each { |entry|
      cust.history_entries.build(entry.attributes)
    }
  end
end
