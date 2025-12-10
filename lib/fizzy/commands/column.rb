module Fizzy
  module Commands
    class Column < Base
      desc "list", "List columns for a board"
      option :board, required: true, type: :string, desc: "Board ID"
      option :page, type: :numeric, desc: "Page number"
      option :all, type: :boolean, default: false, desc: "Fetch all pages"
      def list
        params = {}
        params[:page] = options[:page] if options[:page]

        result = if options[:all]
          client.get_all(client.account_path("/boards/#{options[:board]}/columns"), params)
        else
          client.get(client.account_path("/boards/#{options[:board]}/columns"), params)
        end
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end

      desc "show ID", "Show a specific column"
      option :board, required: true, type: :string, desc: "Board ID"
      def show(id)
        result = client.get(client.account_path("/boards/#{options[:board]}/columns/#{id}"))
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end

      desc "create", "Create a new column"
      option :board, required: true, type: :string, desc: "Board ID"
      option :name, required: true, type: :string, desc: "Column name"
      option :color, type: :string, desc: "CSS color variable name"
      def create
        body = {
          column: {
            name: options[:name],
            color: options[:color]
          }.compact
        }

        result = client.post(client.account_path("/boards/#{options[:board]}/columns"), body)
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end

      desc "update ID", "Update a column"
      option :board, required: true, type: :string, desc: "Board ID"
      option :name, type: :string, desc: "Column name"
      option :color, type: :string, desc: "CSS color variable name"
      def update(id)
        column_params = {}
        column_params[:name] = options[:name] if options.key?(:name)
        column_params[:color] = options[:color] if options.key?(:color)

        result = client.put(client.account_path("/boards/#{options[:board]}/columns/#{id}"), { column: column_params })
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end

      desc "delete ID", "Delete a column"
      option :board, required: true, type: :string, desc: "Board ID"
      def delete(id)
        result = client.delete(client.account_path("/boards/#{options[:board]}/columns/#{id}"))
        output(result || Response.success(data: { deleted: true }))
      rescue Fizzy::Error => e
        output_error(e)
      end
    end
  end
end
