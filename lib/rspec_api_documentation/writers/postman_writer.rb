require 'securerandom'

module RspecApiDocumentation
  module Writers
    class PostmanWriter < Writer
      delegate :docs_dir, :to => :configuration

      def write
        File.open(docs_dir.join("index.json.postman_collection"), "w+") do |f|
          f.write Formatter.to_json(render_template)
        end
      end

      def render_template
        PostmanTemplate.new(folders, requests, configuration)
      end

    private

      def requests
        index.examples.map  do |example|
          example[:metadata][:requests].map do |request|
            PostmanRequest.new(example, request, configuration).as_json
          end
        end.flatten
      end

      def folders
        grouped_examples = index.examples.group_by { |ex| ex[:resource_name] }

        grouped_examples.map do |resource_name, examples|
          requests = examples.map { |ex| ex[:requests] }.flatten
          PostmanFolder.new(resource_name, requests).as_json
        end
      end
    end

    class PostmanTemplate
      # {
      #   "id": "e9f48259-989b-1876-f0b0-925ac0e31bcd",
      #   "name": "AdHawk API",
      #   "description": "",
      #   "order": [],
      #   "folders": [],
      #   "timestamp": 1443744046763,
      #   "owner": "",
      #   "remoteLink": "https://www.getpostman.com/collections/a94a8f0370c167c99723",
      #   "public": false,
      #   "requests": []
      # }

      def initialize(folders, requests, configuration)
        @folders = folders
        @requests = requests
        @configuration = configuration
      end

      def as_json(options = nil)
      {
        id: SecureRandom.uuid,
        name: @configuration.api_name,
        description: "",
        order: [],
        folders: @folders,
        timestamp: Time.now.to_i,
        owner: "",
        remoteLink: "",
        public: false,
        requests: @requests
      }
      end
    end

    class PostmanFolder
      # {
      #   "id": "4aa6ad95-688f-3733-c6ae-01f37f13ccb3",
      #   "name": "Users",
      #   "description": "Users folder",
      #   "order": [
      #     "35278868-1b4f-7b79-2b81-1966d9cc64a4",
      #     "d51c7aa2-383d-f9f3-e7e2-b3df839dacf2"
      #   ],
      #   "owner": "",
      #   "collectionId": "e9f48259-989b-1876-f0b0-925ac0e31bcd"
      # }
      #
      def initialize(resource_name, requests)
        @resource_name = resource_name
        @requests = requests
      end

      def as_json(options = nil)
        {
          id: PostmanFolder.generate_key(@resource_name),
          name: @resource_name,
          description: "",
          order: request_references,
          owner: "",
          collectionId: ""
        }
      end

      def self.generate_key(item)
        item.hash.abs.to_s(16)
      end

      private

      def request_references
        @requests.map { |request| PostmanFolder.generate_key(request) }
      end
    end

    class PostmanRequest
      # {
      #   "id": "d51c7aa2-383d-f9f3-e7e2-b3df839dacf2",
      #   "headers": "Accept: application/vnd.api+json\nContent-Type: application/vnd.api+json\n",
      #   "url": "localhost:3000/v1/users",
      #   "pathVariables": {},
      #   "preRequestScript": "",
      #   "method": "POST",
      #   "collectionId": "e9f48259-989b-1876-f0b0-925ac0e31bcd",
      #   "data": [],
      #   "dataMode": "raw",
      #   "name": "User#create",
      #   "description": "Create a new user",
      #   "descriptionFormat": "html",
      #   "time": 1443744173406,
      #   "version": 2,
      #   "responses": [],
      #   "tests": "",
      #   "currentHelper": "normal",
      #   "helperAttributes": {},
      #   "folder": "4aa6ad95-688f-3733-c6ae-01f37f13ccb3",
      #   "rawModeData": "{\n  \"data\": {\n    \"attributes\": {\n      \"first_name\": \"Christa\",\n      \"last_name\": \"Denesik\",\n      \"email\": \"testing@registration.com\",\n      \"password\": \"foobar123\",\n      \"password_confirmation\": \"foobar123\"\n    }\n  }\n}\n"
      # }

      def initialize(example, request, configuration)
        @example = example
        @request = request
        @configuration = configuration
        @metadata = @example[:metadata]
      end

      def stringify_headers(headers)
        (headers || {}).map do |key, val|
          "#{key}: val"
        end.join "\n"
      end

      def as_json(options = nil)
        {
          id: PostmanFolder.generate_key(@metadata[:full_description]),
          headers: stringify_headers(@request[:request_headers]),
          url: "localhost:3000#{@request[:request_path]}",
          pathVariables: {},
          preRequestScript: "",
          method: @request[:request_method],
          collectionId: "e9f48259-989b-1876-f0b0-925ac0e31bcd",
          data: [],
          dataMode: "raw",
          name: @metadata[:description],
          description: @metadata[:full_description],
          descriptionFormat: "html",
          time: Time.now.to_i,
          version: 2,
          responses: [],
          tests: "",
          currentHelper: "normal",
          helperAttributes: {},
          folder: PostmanFolder.generate_key(@metadata[:resource_name]),
          rawModeData: @request[:request_body]
        }
      end
    end
  end
end
