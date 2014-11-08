class CustomerSearch

  attr_reader :opts, :c_opts, :h_opts, :customer_ids, :history, :result


  def self.search(opts)
    new(opts).search
  end


  def self.setup
    [Customer, HistoryEntry].each { |klass| klass.es.index.create }
  end


  def initialize(_opts)
    @opts = _opts
    size  = sanitized_size
    time  = sanitized_timespan

    @c_opts = build_query_for(:c, size)
    @h_opts = build_query_for(:h, size, time)
  end


  def c_query?
    !opts[:c].blank?
  end


  def h_query?
    !opts[:h].blank?
  end


  def sanitized_timespan
    delta = opts.fetch(:t, '4w')
    delta[/\A[0-9]+[mhdwM]\z/] ? "now-#{delta}" : 'now-4w'
  end


  def sanitized_size
    size = opts.fetch(:s, 100)
    size > 100 ? 100 : size
  end


  def query_body_for(key, size)
    { body: {
        query: {
          query_string: {
            query: opts.fetch(key, '')
          }
        },
        filter: {bool: {must: []}},
        size:   size
    } }
  end


  def build_query_for(key, size, from=nil)
    query_body_for(key, size).tap { |hash|
      add_timerange_to(hash, from) if from
    }
  end


  def add_timerange_to(hash, from)
    hash[:body][:filter][:bool][:must] << {
      range: {created_at: {from: from, to: 'now'}}
    }
  end


  def scoped_history_query
    h_opts.tap { |q|
      q[:body][:filter][:bool][:must] << {
        terms: {
          customer_id: customer_ids.map(&:to_s)
        }
      } if c_query?
    }
  end


  def search
    @customer_ids = find_customer_ids
    @history      = find_history_entries
    @result       = aggregate_customers
  end


  def customer_search_for(_opts)
    Customer.es.search(_opts).results
  end


  def find_customer_ids
    return [] unless c_query?
    customer_search_for(c_opts).map(&:id)
  rescue => e
    puts "#{Time.now.utc} :: An error happened: #{e.message}"
    []
  end


  def history_search_for(_opts)
    HistoryEntry.es.search(_opts).results
  end


  def find_history_entries
    return {} unless h_query?
    _opts = scoped_history_query

    history_search_for(_opts).group_by { |he| he.customer_id }
  rescue => e
    puts "#{Time.now.utc} :: An error happened: #{e.message}"
    {}
  end


  def aggregate_customers
    filtered_customers.each_with_object([]) { |cust, result|
      assemble_entries_from(history, cust) if h_query?
      result << cust
    }
  end


  def scoped_customer_ids
    keys = c_query? ? customer_ids : (h_query? ? history.keys : [])
    keys = h_query? ? keys.map(&:to_s) & history.keys : keys
  end


  def filtered_customers
    Customer.where(:_id.in => scoped_customer_ids)
            .without('history_entries')
  end


  def assemble_entries_from(history, cust)
    history[cust.id.to_s].each { |entry|
      cust.history_entries.build(entry.attributes)
    }
  end
end
