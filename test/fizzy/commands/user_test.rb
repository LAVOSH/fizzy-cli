require "test_helper"

class Fizzy::Commands::UserTest < Fizzy::TestCase
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

  def test_list_returns_users
    stub_request(:get, "https://app.fizzy.do/test_account/users")
      .to_return(
        status: 200,
        body: '[{"id": "1", "name": "Alice"}, {"id": "2", "name": "Bob"}]',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::User.new.invoke(:list, [])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal 2, result["data"].length
    assert_equal "Alice", result["data"][0]["name"]
  end

  def test_show_returns_user
    stub_request(:get, "https://app.fizzy.do/test_account/users/1")
      .to_return(
        status: 200,
        body: '{"id": "1", "name": "Alice", "email": "alice@example.com"}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::User.new.invoke(:show, ["1"])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal "Alice", result["data"]["name"]
    assert_equal "alice@example.com", result["data"]["email"]
  end

  def test_update_user
    stub_request(:put, "https://app.fizzy.do/test_account/users/1")
      .with(
        body: { user: { name: "Alice Smith" } }.to_json
      )
      .to_return(
        status: 200,
        body: '{"id": "1", "name": "Alice Smith"}',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::User.new([], { name: "Alice Smith" }).invoke(:update, ["1"])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal "Alice Smith", result["data"]["name"]
  end

  def test_deactivate_user
    stub_request(:delete, "https://app.fizzy.do/test_account/users/1")
      .to_return(status: 204, body: "")

    output = capture_output do
      Fizzy::Commands::User.new.invoke(:deactivate, ["1"])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert result["data"]["deactivated"]
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
