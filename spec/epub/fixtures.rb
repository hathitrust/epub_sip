# frozen_string_literal: true

RSpec.shared_context "with epub fixtures" do
  let(:input) { "#{fixture}/test.epub" }
  let(:fixture) { File.dirname(__FILE__) + "/../support/fixtures/#{pt_objid}" }
  let(:pt_objid) { "ark+=87302=t00000001" }
end
