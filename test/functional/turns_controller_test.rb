require File.dirname(__FILE__) + '/../test_helper'
require 'turns_controller'

# Re-raise errors caught by the controller.
class TurnsController; def rescue_action(e) raise e end; end

class TurnsControllerTest < Test::Unit::TestCase
  fixtures :turns

  def setup
    @controller = TurnsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = turns(:first).id
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:turns)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:turn)
    assert assigns(:turn).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:turn)
  end

  def test_create
    num_turns = Turn.count

    post :create, :turn => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_turns + 1, Turn.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:turn)
    assert assigns(:turn).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Turn.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Turn.find(@first_id)
    }
  end
end
