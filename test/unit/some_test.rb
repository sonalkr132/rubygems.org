require 'test_helper'

class SomeTest < ActiveSupport::TestCase
  test 'something' do
    tsv_sql = "SELECT to_tsvector('a fat  cat sat on a mat - it ate a fat rats')"
    puts ActiveRecord::Base.connection.execute(tsv_sql).first.inspect

    rubygem = create(:rubygem)
    rubygem.reload
    puts rubygem.inspect
  end
end