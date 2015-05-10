require 'test_helper'

class NoticeControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get write" do
    get :write
    assert_response :success
  end

  test "should get view" do
    get :view
    assert_response :success
  end

end
