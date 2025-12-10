module Fizzy
  module Commands
    class Board < Base
      desc "list", "List all boards"
      option :page, type: :numeric, desc: "Page number"
      option :all, type: :boolean, default: false, desc: "Fetch all pages"
      def list
        params = {}
        params[:page] = options[:page] if options[:page]

        result = if options[:all]
          client.get_all(client.account_path("/boards"), params)
        else
          client.get(client.account_path("/boards"), params)
        end
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end

      desc "show ID", "Show a specific board"
      def show(id)
        result = client.get(client.account_path("/boards/#{id}"))
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end

      desc "create", "Create a new board"
      option :name, required: true, type: :string, desc: "Board name"
      option :all_access, type: :boolean, default: true, desc: "Allow all users to access"
      option :auto_postpone_period, type: :numeric, desc: "Auto-postpone period in days"
      def create
        body = {
          board: {
            name: options[:name],
            all_access: options[:all_access],
            auto_postpone_period: options[:auto_postpone_period]
          }.compact
        }

        result = client.post(client.account_path("/boards"), body)
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end

      desc "update ID", "Update a board"
      option :name, type: :string, desc: "Board name"
      option :all_access, type: :boolean, desc: "Allow all users to access"
      option :user_ids, type: :string, desc: "Comma-separated user IDs for access"
      option :auto_postpone_period, type: :numeric, desc: "Auto-postpone period in days"
      def update(id)
        board_params = {}
        board_params[:name] = options[:name] if options.key?(:name)
        board_params[:all_access] = options[:all_access] if options.key?(:all_access)
        board_params[:auto_postpone_period] = options[:auto_postpone_period] if options.key?(:auto_postpone_period)

        if options[:user_ids]
          board_params[:user_ids] = options[:user_ids].split(",").map(&:strip)
        end

        result = client.put(client.account_path("/boards/#{id}"), { board: board_params })
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end

      desc "delete ID", "Delete a board"
      def delete(id)
        result = client.delete(client.account_path("/boards/#{id}"))
        output(result || Response.success(data: { deleted: true }))
      rescue Fizzy::Error => e
        output_error(e)
      end
    end
  end
end
