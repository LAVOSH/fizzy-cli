module Fizzy
  module Commands
    class Card < Base
      desc "list", "List cards"
      option :board, type: :string, desc: "Filter by board ID"
      option :column, type: :string, desc: "Filter by column ID"
      option :tag, type: :string, desc: "Filter by tag ID"
      option :assignee, type: :string, desc: "Filter by assignee ID"
      option :status, type: :string, desc: "Filter by status (published, closed, not_now)"
      option :page, type: :numeric, desc: "Page number"
      option :all, type: :boolean, default: false, desc: "Fetch all pages"
      def list
        params = {}
        params[:board_id] = options[:board] if options[:board]
        params[:column_id] = options[:column] if options[:column]
        params[:tag_id] = options[:tag] if options[:tag]
        params[:assignee_id] = options[:assignee] if options[:assignee]
        params[:status] = options[:status] if options[:status]
        params[:page] = options[:page] if options[:page]

        result = if options[:all]
          client.get_all(client.account_path("/cards"), params)
        else
          client.get(client.account_path("/cards"), params)
        end
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end

      desc "show NUMBER", "Show a specific card by number"
      def show(number)
        result = client.get(client.account_path("/cards/#{number}"))
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end

      desc "create", "Create a new card"
      option :board, required: true, type: :string, desc: "Board ID"
      option :title, required: true, type: :string, desc: "Card title"
      option :description, type: :string, desc: "Card description (rich text/HTML)"
      option :description_file, type: :string, desc: "Read description from file"
      option :status, type: :string, desc: "Card status"
      option :tag_ids, type: :string, desc: "Comma-separated tag IDs"
      def create
        card_params = {
          title: options[:title]
        }

        if options[:description_file]
          card_params[:description] = File.read(options[:description_file])
        elsif options[:description]
          card_params[:description] = options[:description]
        end

        card_params[:status] = options[:status] if options[:status]

        if options[:tag_ids]
          card_params[:tag_ids] = options[:tag_ids].split(",").map(&:strip)
        end

        result = client.post(client.account_path("/boards/#{options[:board]}/cards"), { card: card_params })
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end

      desc "update NUMBER", "Update a card"
      option :title, type: :string, desc: "Card title"
      option :description, type: :string, desc: "Card description (rich text/HTML)"
      option :description_file, type: :string, desc: "Read description from file"
      option :status, type: :string, desc: "Card status"
      option :tag_ids, type: :string, desc: "Comma-separated tag IDs"
      def update(number)
        card_params = {}
        card_params[:title] = options[:title] if options.key?(:title)
        card_params[:status] = options[:status] if options.key?(:status)

        if options[:description_file]
          card_params[:description] = File.read(options[:description_file])
        elsif options.key?(:description)
          card_params[:description] = options[:description]
        end

        if options[:tag_ids]
          card_params[:tag_ids] = options[:tag_ids].split(",").map(&:strip)
        end

        result = client.put(client.account_path("/cards/#{number}"), { card: card_params })
        output(result)
      rescue Fizzy::Error => e
        output_error(e)
      end

      desc "delete NUMBER", "Delete a card"
      def delete(number)
        result = client.delete(client.account_path("/cards/#{number}"))
        output(result || Response.success(data: { deleted: true }))
      rescue Fizzy::Error => e
        output_error(e)
      end
    end
  end
end
