class HistoryEntry

  include Mongoid::Document
  include Mongoid::Elasticsearch


  elasticsearch! index_mappings: {
    'tags'        => {type: 'string', analyzer: 'snowball'},
    'remarks'     => {type: 'string', analyzer: 'snowball'},
    'mailbox'     => {type: 'string', index:    :not_analyzed},
    'call_id'     => {type: 'string', index:    :not_analyzed},
    'user_id'     => {type: 'integer'},
    'caller_id'   => {type: 'string', index:    :not_analyzed},
    'created_at'  => {type: 'date',   index:    :not_analyzed},
    'customer_id' => {type: 'string', index:    :not_analyzed}
  }


  field :tags,        type: Array,  default: -> { [] }
  field :remarks,     type: String, default: ""
  field :mailbox,     type: String
  field :call_id,     type: String
  field :user_id,     type: Integer
  field :caller_id,   type: String
  field :created_at,  type: Time,   default: -> { Time.now.utc }
  field :customer_id, type: String

  embedded_in :customer
  before_save :set_customer_id


  def set_customer_id
    self.customer_id = customer.try(:id).to_s
  end


  def as_indexed_json
    serializable_hash.reject { |k, v|
      %w(_id).include?(k)
    }.tap { |h|
      h['created_at'] = h['created_at'].iso8601
    }
  end
end
