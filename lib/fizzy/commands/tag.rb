module Fizzy
  module Commands
    class Tag < Base
      desc "list", "List all tags"
      option :page, type: :numeric, desc: "Page number"
      option :all, type: :boolean, default: false, desc: "Fetch all pages"
      def list
        params = {}
        params[:page] = options[:page] if options[:page]

        result = if options[:all]
          client.get_all(client.account_path("/tags"), params)
        else
          client.get(client.account_path("/tags"), params)
        end
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end
    end
  end
end
