require "test_helper"

class Fizzy::Commands::ColumnTest < Fizzy::TestCase
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

  def test_list_returns_columns
    stub_request(:get, "https://app.fizzy.do/test_account/boards/10/columns")
      .to_return(
        status: 200,
        body: '[{"id": "1", "name": "To Do"}, {"id": "2", "name": "Done"}]',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Column.new([], { board: "10" }).invoke(:list, [])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal 2, result["data"].length
    assert_equal "To Do", result["data"][0]["name"]
  end

  def test_show_returns_column
    stub_request(:get, "https://app.fizzy.do/test_account/boards/10/columns/1")
      .to_return(
        status: 200,
        body: '{"id": "1", "name": "To Do", "color": "blue"}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Column.new([], { board: "10" }).invoke(:show, ["1"])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal "To Do", result["data"]["name"]
    assert_equal "blue", result["data"]["color"]
  end

  def test_create_column
    stub_request(:post, "https://app.fizzy.do/test_account/boards/10/columns")
      .with(
        body: { column: { name: "In Progress" } }.to_json
      )
      .to_return(
        status: 201,
        body: '{"id": "3", "name": "In Progress"}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Column.new([], { board: "10", name: "In Progress" }).invoke(:create, [])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal "In Progress", result["data"]["name"]
  end

  def test_create_with_color
    stub_request(:post, "https://app.fizzy.do/test_account/boards/10/columns")
      .with(
        body: { column: { name: "Review", color: "var(--purple)" } }.to_json
      )
      .to_return(
        status: 201,
        body: '{"id": "4", "name": "Review", "color": "var(--purple)"}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Column.new([], { board: "10", name: "Review", color: "var(--purple)" }).invoke(:create, [])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal "var(--purple)", result["data"]["color"]
  end

  def test_update_column
    stub_request(:put, "https://app.fizzy.do/test_account/boards/10/columns/1")
      .with(
        body: { column: { name: "Done", color: "green" } }.to_json
      )
      .to_return(
        status: 200,
        body: '{"id": "1", "name": "Done", "color": "green"}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Column.new([], { board: "10", name: "Done", color: "green" }).invoke(:update, ["1"])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal "Done", result["data"]["name"]
    assert_equal "green", result["data"]["color"]
  end

  def test_delete_column
    stub_request(:delete, "https://app.fizzy.do/test_account/boards/10/columns/1")
      .to_return(status: 204, body: "")

    output = capture_output do
      Fizzy::Commands::Column.new([], { board: "10" }).invoke(:delete, ["1"])
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
