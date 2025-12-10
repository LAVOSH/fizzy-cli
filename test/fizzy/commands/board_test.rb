require "test_helper"

class Fizzy::Commands::BoardTest < Fizzy::TestCase
  def setup
    super
    @original_home = ENV["HOME"]
    @temp_dir = Dir.mktmpdir
    ENV["HOME"] = @temp_dir

    config = Fizzy::Config.new
    config.save!(token: "test_token", account: "test_account")
  end

  def teardown
    super
    ENV["HOME"] = @original_home
    FileUtils.rm_rf(@temp_dir)
  end

  def test_list_returns_boards
    stub_request(:get, "https://app.fizzy.do/test_account/boards")
      .with(headers: { "Authorization" => "Bearer test_token" })
      .to_return(
        status: 200,
        body: '[{"id": "1", "name": "Board 1"}, {"id": "2", "name": "Board 2"}]',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Board.new.invoke(:list, [])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal 2, result["data"].length
    assert_equal "Board 1", result["data"][0]["name"]
  end

  def test_list_with_page
    stub_request(:get, "https://app.fizzy.do/test_account/boards")
      .with(query: { "page" => "2" })
      .to_return(
        status: 200,
        body: '[{"id": "3", "name": "Board 3"}]',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Board.new([], { page: 2 }).invoke(:list, [])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal "Board 3", result["data"][0]["name"]
  end

  def test_list_with_all_pages
    stub_request(:get, "https://app.fizzy.do/test_account/boards")
      .to_return(
        status: 200,
        body: '[{"id": "1", "name": "Board 1"}]',
        headers: {
          "Content-Type" => "application/json",
          "Link" => '<https://app.fizzy.do/test_account/boards?page=2>; rel="next"'
        }
      )

    stub_request(:get, "https://app.fizzy.do/test_account/boards")
      .with(query: { "page" => "2" })
      .to_return(
        status: 200,
        body: '[{"id": "2", "name": "Board 2"}]',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Board.new([], { all: true }).invoke(:list, [])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal 2, result["data"].length
  end

  def test_show_returns_board
    stub_request(:get, "https://app.fizzy.do/test_account/boards/123")
      .to_return(
        status: 200,
        body: '{"id": "123", "name": "My Board"}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Board.new.invoke(:show, ["123"])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal "123", result["data"]["id"]
    assert_equal "My Board", result["data"]["name"]
  end

  def test_show_not_found
    stub_request(:get, "https://app.fizzy.do/test_account/boards/999")
      .to_return(status: 404, body: '{"error": "Not found"}')

    assert_raises(SystemExit) do
      capture_output do
        Fizzy::Commands::Board.new.invoke(:show, ["999"])
      end
    end
  end

  def test_create_board
    stub_request(:post, "https://app.fizzy.do/test_account/boards")
      .with(
        body: { board: { name: "New Board", all_access: true } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      .to_return(
        status: 201,
        body: '{"id": "456", "name": "New Board", "all_access": true}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Board.new([], { name: "New Board", all_access: true }).invoke(:create, [])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal "456", result["data"]["id"]
    assert_equal "New Board", result["data"]["name"]
  end

  def test_create_with_auto_postpone
    stub_request(:post, "https://app.fizzy.do/test_account/boards")
      .with(
        body: { board: { name: "Board", all_access: true, auto_postpone_period: 7 } }.to_json
      )
      .to_return(
        status: 201,
        body: '{"id": "789", "name": "Board", "auto_postpone_period": 7}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Board.new([], { name: "Board", all_access: true, auto_postpone_period: 7 }).invoke(:create, [])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal 7, result["data"]["auto_postpone_period"]
  end

  def test_update_board
    stub_request(:put, "https://app.fizzy.do/test_account/boards/123")
      .with(
        body: { board: { name: "Updated Board" } }.to_json
      )
      .to_return(
        status: 200,
        body: '{"id": "123", "name": "Updated Board"}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Board.new([], { name: "Updated Board" }).invoke(:update, ["123"])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal "Updated Board", result["data"]["name"]
  end

  def test_update_with_user_ids
    stub_request(:put, "https://app.fizzy.do/test_account/boards/123")
      .with(
        body: { board: { user_ids: ["1", "2", "3"] } }.to_json
      )
      .to_return(
        status: 200,
        body: '{"id": "123", "user_ids": ["1", "2", "3"]}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Board.new([], { user_ids: "1, 2, 3" }).invoke(:update, ["123"])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal %w[1 2 3], result["data"]["user_ids"]
  end

  def test_delete_board
    stub_request(:delete, "https://app.fizzy.do/test_account/boards/123")
      .to_return(status: 204, body: "")

    output = capture_output do
      Fizzy::Commands::Board.new.invoke(:delete, ["123"])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert result["data"]["deleted"]
  end

  private

  def capture_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
