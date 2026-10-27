# frozen_string_literal: true

require "test_helper"

class TestFunctionalWebApp < Minitest::Test
  def click_altcha
    check "I'm not a robot", allow_label_click: true
    assert_text 'Verified', wait: 10
  end

  def prepare_login
    visit '/login'

    fill_in 'password', with: 'hola'
    click_altcha
  end

  def login
    prepare_login
    click_button 'Login'
  end

  def fill_out_comment_form username, password, comment
    find(:xpath, '//*[text()="Post a comment"]').click
    fill_in 'username', with: username
    fill_in 'password', with: password
    fill_in 'comment', with: comment
    click_altcha
  end

  def post_comment username, password, comment
    fill_out_comment_form username, password, comment
    click_button 'Post comment'
  end

  def approve_comment comment
    find(:xpath, "//p[text()='#{comment}']/following-sibling::form//input[@value='Approve']").click
  end

  def reject_comment comment
    find(:xpath, "//p[text()='#{comment}']/following-sibling::form//input[@value='Reject']").click
  end

  def remove_altcha_payload(form)
    field = form.find('input[name="altcha"]', visible: :all)
    refute_empty field.value

    page.execute_script('arguments[0].remove()', field)
  end

  def tamper_with_csrf_token(form, token)
    form.find('input[name="authenticity_token"]', visible: :all)

    page.execute_script(<<~JS, form, token)
      const field = arguments[0].querySelector(
        'input[name="authenticity_token"]'
      );

      if (arguments[1] === null) {
        field.remove();
      } else {
        field.value = arguments[1];
      }
    JS
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

  def test_post_comment_validates_altcha
    thread_url = '/threads/123'
    body = "ALTCHA test #{SecureRandom.uuid}"

    visit thread_url
    fill_out_comment_form Faker::Internet.username, Faker::Internet.password, body

    form = find('.convos-comment-form form')
    remove_altcha_payload(form)
    comment_count = Comment.count

    click_button 'Post comment'

    assert_field 'comment', with: '', visible: :all
    assert_current_path thread_url
    assert_equal comment_count, Comment.count
    refute Comment.exists?(body: body)
  end

  def test_login_validates_csrf
    [nil, 'invalid-token'].each do |token|
      prepare_login

      tamper_with_csrf_token(find('form'), token)
      session_count = Session.count

      click_button 'Login'

      assert_text 'Forbidden'
      assert_equal session_count, Session.count

      visit '/moderate'
      assert_text 'Login'
    end
  end

  def test_moderation_validates_csrf
    body = "CSRF test #{SecureRandom.uuid}"

    visit '/threads/123'
    post_comment Faker::Internet.username, Faker::Internet.password, body
    assert_field 'comment', with: '', visible: :all
    comment = Comment.find_by!(body: body)

    login
    assert_text 'Moderate'

    ['Approve', 'Reject'].each do |action|
      [nil, 'invalid-token'].each do |token|
        visit '/moderate'

        button = find("input[value='#{action}'][formaction*='#{comment.id}']")
        form = button.find(:xpath, 'ancestor::form')

        tamper_with_csrf_token(form, token)
        button.click

        assert_text 'Forbidden'
        assert Comment.exists?(comment.id)
        assert_equal 'unmoderated', comment.reload.status
      end
    end
  ensure
    comment&.destroy!
  end

  def test_post_comment_validates_csrf
    [nil, 'invalid-token'].each do |token|
      visit '/threads/123'
      body = "CSRF test #{SecureRandom.uuid}"

      fill_out_comment_form Faker::Internet.username, Faker::Internet.password, body

      form = find('.convos-comment-form form')
      tamper_with_csrf_token(form, token)
      comment_count = Comment.count

      click_button 'Post comment'

      assert_text 'Forbidden'
      assert_equal comment_count, Comment.count
      refute Comment.exists?(body: body)
    end
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
