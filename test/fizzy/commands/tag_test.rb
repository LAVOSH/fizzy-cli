require "test_helper"

class Fizzy::Commands::TagTest < Fizzy::TestCase
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

  def test_list_returns_tags
    stub_request(:get, "https://app.fizzy.do/test_account/tags")
      .to_return(
        status: 200,
        body: '[{"id": "1", "title": "bug"}, {"id": "2", "title": "feature"}]',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Tag.new.invoke(:list, [])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal 2, result["data"].length
    assert_equal "bug", result["data"][0]["title"]
    assert_equal "feature", result["data"][1]["title"]
  end

  def test_list_with_pagination
    stub_request(:get, "https://app.fizzy.do/test_account/tags")
      .with(query: { "page" => "2" })
      .to_return(
        status: 200,
        body: '[{"id": "3", "title": "enhancement"}]',
        headers: { "Content-Type" => "application/json" }
      )

    output = capture_output do
      Fizzy::Commands::Tag.new([], { page: 2 }).invoke(:list, [])
    end

    result = JSON.parse(output)
    assert result["success"]
    assert_equal "enhancement", result["data"][0]["title"]
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
