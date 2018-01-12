# frozen_string_literal: true

RSpec.shared_context "with simple epub fixtures" do
  let(:simple_epub) { "#{fixture}/test.epub" }
  let(:fixture) { File.dirname(__FILE__) + "/../support/fixtures/#{pt_objid}" }
  let(:pt_objid) { "ark+=87302=t00000001" }
end
