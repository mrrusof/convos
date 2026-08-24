# frozen_string_literal: true

require "test_helper"

class TestFunctionalWebApp < Minitest::Test
  def click_altcha
    check "I'm not a robot", allow_label_click: true
    assert_text 'Verified', wait: 10
  end

  def login
    visit '/login'

    fill_in 'password', with: 'hola'
    click_altcha
    click_button 'Login'
  end

  def post_comment username, password, comment
    find(:xpath, '//*[text()="Post a comment"]').click
    fill_in 'username', with: username
    fill_in 'password', with: password
    fill_in 'comment', with: comment
    click_altcha
    click_button 'Post comment'
  end

  def approve_comment comment
    find(:xpath, "//p[text()='#{comment}']/following-sibling::form//input[@value='Approve']").click
  end

  def reject_comment comment
    find(:xpath, "//p[text()='#{comment}']/following-sibling::form//input[@value='Reject']").click
  end

  def test_sessions
    login

    assert_text 'Moderate'

    click_on 'Logout'

    assert_text 'Login'
  end

  def test_moderation
    thread_url = "/threads/123"
    username = Faker::Internet.username
    password = Faker::Internet.password
    comment1 = Faker::Lorem.paragraph
    comment2 = Faker::Lorem.paragraph
    comment3 = Faker::Lorem.paragraph

    # Post comments

    visit thread_url

    post_comment username, password, comment1
    assert_no_text comment1

    post_comment username, password, comment2
    assert_no_text comment2
  
    post_comment username, password, comment3
    assert_no_text comment3

    # Moderate comments

    login

    assert_text comment1
    assert_text comment2
    assert_text comment3

    approve_comment comment1
    assert_no_text comment1
    assert_text comment2
    assert_text comment3

    reject_comment comment2
    assert_no_text comment1
    assert_no_text comment2
    assert_text comment3

    approve_comment comment3
    assert_no_text comment1
    assert_no_text comment2
    assert_no_text comment3

    # Approved comments are published

    visit thread_url

    assert_text comment1
    assert_no_text comment2
    assert_text comment3

    # Rejected comment is purged
    assert !Comment.exists?(body: comment2)
  end

  def test_moderate_is_authenticated
    # Without cookie
    visit '/moderate'
    assert_text 'Login'

    # With cookie

    Convos::Api.get '/set_bad_session_id' do
      session[:id] = 'invalid-session'
    end

    visit '/set_bad_session_id'
    visit '/moderate'
    assert_text 'Login'
  end

  def test_not_found
    visit '/does-not-exist'
    assert_text 'Not found'
  end

  def test_internal_server_error
    Convos::Api.get '/raises_error' do
      raise 'OMG an error!'
    end

    visit '/raises_error'
    assert_text 'Internal server error'
  end
end
