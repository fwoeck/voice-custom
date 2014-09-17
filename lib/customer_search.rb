module CustomerSearch

  def search(opts)
    c_opts = opts.fetch(:customer, {}) # TODO This is not yet used.
    h_opts = opts.fetch(:history,  {})

    group = group_entries_by_customer(h_opts)
    aggregate_customers_from(group)
  end


  def group_entries_by_customer(opts)
    HistoryEntry.es.search(opts).results
                .group_by { |he| he.customer_id }
  end


  def aggregate_customers_from(group)
    blank_customers(group.keys).each_with_object([]) { |cust, result|
      assemble_entries_from(group, cust)
      result << cust
    }
  end


  def blank_customers(keys)
    Customer.where(:_id.in => keys).without('history_entries')
  end


  def assemble_entries_from(group, cust)
    group[cust.id.to_s].each { |entry|
      cust.history_entries.build(entry.attributes)
    }
  end
end
