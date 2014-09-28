class HistoryEntry

  include Mongoid::Document
  include Mongoid::Elasticsearch


  elasticsearch! index_mappings: {
    'tags'        => {type: 'string', analyzer: 'snowball'},
    'remarks'     => {type: 'string', analyzer: 'snowball'},
    'mailbox'     => {type: 'string'},
    'call_id'     => {type: 'string'},
    'user_id'     => {type: 'integer'},
    'caller_id'   => {type: 'string'},
    'created_at'  => {type: 'string'},
    'customer_id' => {type: 'string'}
  }


  field :tags,        type: Array,    default: -> { [] }
  field :remarks,     type: String,   default: ""
  field :mailbox,     type: String
  field :call_id,     type: String
  field :user_id,     type: Integer
  field :caller_id,   type: String
  field :created_at,  type: DateTime, default: -> { Time.now.utc }
  field :customer_id, type: String

  embedded_in :customer
  before_save :set_customer_id


  def set_customer_id
    self.customer_id = customer.try(:id).to_s
  end
end
