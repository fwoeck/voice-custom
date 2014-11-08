require 'spec_helper'

require 'history_entry'
require 'customer_search'
require 'customer_crm'
require 'customer'

describe CustomerSearch do

  let(:opts) { {c: 'vickie OR elbert', h: 'NOT closed', t: '1d', s: 100} }
  let(:cs)   { CustomerSearch.new(opts) }

  let(:c_results) { Marshal.load(File.read './spec/fixtures/c-results') }
  let(:h_results) { Marshal.load(File.read './spec/fixtures/h-results') }
  let(:customers) { Marshal.load(File.read './spec/fixtures/customers') }


  before do
    allow(cs).to receive(:customer_search_for) { c_results }
    allow(cs).to receive(:history_search_for)  { h_results }
    allow(cs).to receive(:filtered_customers)  { customers }
    cs.search
  end


  it 'builds proper c_opts' do
    expect(
     cs.c_opts
    ).to eql(
      { body: {
        query: {
          query_string: {
            query: 'vickie OR elbert'
          }
        },
        filter: {
          bool: {must: []}
        },
        size: 100}
      }
    )
  end


  it 'builds proper h_opts' do
    expect(
     cs.h_opts
    ).to eql(
      { body: {
          query: {
            query_string: {query: 'NOT closed'}
          },
          filter: {
            bool: {
              must: [
                {range: {created_at: {from: 'now-1d', to: 'now'}}},
                {terms: {
                  customer_id: [
                    '545dd956766f69047c3f0200', '545b1d62766f6960c5d30200',
                    '545dd956766f69047c1d0200', '545b1d57766f6960c5020000',
                    '545dd956766f69047c210200'
                  ]
                }
                }
              ]
            }
          },
          size: 100
      } }
    )
  end


  it 'scopes the customer ids' do
    expect(
      cs.scoped_customer_ids.map(&:to_s)
    ).to eql(
      [ '545dd956766f69047c3f0200',
        '545dd956766f69047c1d0200',
        '545dd956766f69047c210200'
      ]
    )
  end


  it 'finds the customer ids' do
    expect(
      cs.customer_ids.map(&:to_s)
    ).to eql(
      [ '545dd956766f69047c3f0200',
        '545b1d62766f6960c5d30200',
        '545dd956766f69047c1d0200',
        '545b1d57766f6960c5020000',
        '545dd956766f69047c210200'
      ]
    )
  end


  it 'builds the history hash I' do
    expect(cs.history.keys).to eql(
      [ '545dd956766f69047c1d0200',
        '545dd956766f69047c210200',
        '545dd956766f69047c3f0200'
      ]
    )
  end


  it 'builds the history hash II' do
    expect(
      cs.history.values.flatten.map(&:_id).map(&:to_s)
    ).to eql(
      [ '545ddf13766f69047c1a0600',
        '545de3ba766f69047c510600',
        '545dea07766f69047cd20700',
        '545deb10766f69047c850800',
        '545de896766f69047ce70600'
      ]
    )
  end


  it 'assembles the results' do
    expect(cs.result).to eql(
      Marshal.load(File.read './spec/fixtures/search-result')
    )
  end
end
