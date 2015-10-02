require "spec_helper"
require "rspec_api_documentation/writers/postman_writer"

describe RspecApiDocumentation::Writers::PostmanWriter do
  let(:configuration) { RspecApiDocumentation::Configuration.new }
  let(:requests) {[
    {
      request_method: "GET",
      request_path: "/greetings",
      request_headers: { "Header" => "value" },
      request_query_parameters: { "foo" => "bar", "baz" => "quux" },
      response_status: 200,
      response_status_text: "OK",
      response_headers: { "Header" => "value", "Foo" => "bar" },
      response_body: "body"
    },
    {
      request_method: "POST",
      request_path: "/greetings",
      request_body: "body",
      response_status: 404,
      response_status_text: "Not Found",
      response_headers: { "Header" => "value" },
      response_body: "body"
    }
  ]}

  let(:rspec_examples) do
    [
      { resource_name: "Foo Bar", description: "ABCDEFG", metadata: { requests: requests } },
      { resource_name: "Baz Bar", description: "ABCDEFG", metadata: { requests: requests } }
    ]
  end

  let(:index) do
    Struct.new(:examples).new(rspec_examples)
  end

  subject { described_class.new index, configuration }

  describe "#render_template" do
    let(:serialized_examples) { subject.render_template.as_json }

    it "includes the correct keys" do
      expect(serialized_examples).to have_key :folders
      expect(serialized_examples).to have_key :requests
      expect(serialized_examples).to have_key :id
      expect(serialized_examples).to have_key :name
      expect(serialized_examples).to have_key :description
    end

    it "correctly represents the folders" do
      folders = serialized_examples[:folders]

      expect(folders.size).to eq 2
    end

    it "correctly represents the requests" do
      requests = serialized_examples[:requests]

      expect(requests.size).to eq 4
    end
  end
end
