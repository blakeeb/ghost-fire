require 'test_helper'

class AdminControllerTest < ActionController::TestCase
  test "should get parse" do
    get :parse
    assert_response :success
  end

end
