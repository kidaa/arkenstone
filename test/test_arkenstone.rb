require 'spec_helper'

class ArkenstoneTest < Test::Unit::TestCase
  
  def test_arkenstone_url_set
    eval %(
      class ArkenstoneUrlTest
        include Arkenstone::Document
        url 'http://example.com'
      end
    )

    assert(ArkenstoneUrlTest)
    assert(ArkenstoneUrlTest.arkenstone_url == 'http://example.com')
  end

  def test_arkenstone_attributes_set
    eval %(
      class ArkenstoneAttributesTest
        include Arkenstone::Document
        attributes :name, :age
      end
    )
    arkenstone = ArkenstoneAttributesTest.new

    assert(ArkenstoneAttributesTest.arkenstone_attributes == [:name, :age])
    assert(arkenstone.respond_to?(:name))
    assert(arkenstone.respond_to?(:age))
  end

  def test_builds_from_params
    user = User.build(user_options)
    assert(user.class == User, "user class was not User")
    assert(user.age == 18, "user's age was not 18")
  end
  
  def test_returns_json
    user = User.build(user_options)
    assert(user.to_json, 'user#to_json method does not exist')
    assert(user.arkenstone_json, 'user#arkenstone_json method does not exist')
    assert(user.to_json == user.arkenstone_json, 'does not match json')
  end

  def test_attribute_changes_updates_json
    user = User.build(user_options)
    old_json = user.to_json
    user.bearded = false
    assert(user.to_json != old_json)
    assert(user.to_json == user_options.merge(bearded: false).to_json)
    assert(user.arkenstone_json == user.to_json)
  end

  def test_finds_instance_by_id
    user_json = user_options.merge({id: 1}).to_json
    stub_request(:get, User.arkenstone_url + '1').to_return(body: user_json)
    user = User.find(1)
    assert user 
    assert user.id == 1
  end

  def test_instance_not_found_is_nil
    stub_request(:any, User.arkenstone_url + '1').to_return(body: "", status: 404)
    user = User.find 1
    assert_nil user
  end

  def test_finds_all_instances
    users_json = [
      user_options.merge({id: 1}),
      user_options.merge({id: 2})
    ].to_json

    stub_request(:get, User.arkenstone_url).to_return(body: users_json)
    users = User.all
    assert(users.length == 2)
    assert((users.select {|user| user.id == 1}).length == 1)
    assert((users.select {|user| user.id == 2}).length == 1)
  end

  def test_save_new_record
    user = User.build user_options
    assert(!user.id, 'user has an id')

    stub_request(:post, User.arkenstone_url).to_return(body: user_options.merge({id: 1}).to_json)
    user.save
    assert(user.id == 1, 'user does not have an id')
  end

  def test_save_current_record
    user = User.build user_options.merge({id: 1, bearded: false})
    assert(user.bearded != true)

    stub_request(:put, "#{User.arkenstone_url}#{user.id}").to_return(body: user_options.merge({id: 1, bearded: true}).to_json)
    user.bearded = true
    user.save

    assert(user.bearded == true)

    stub_request(:get, "#{User.arkenstone_url}#{user.id}").to_return(body: user_options.merge({id: 1, bearded: true}).to_json)
    user = User.find(user.id)
    assert(user.bearded == true)
  end

  def test_creates
    stub_request(:post, User.arkenstone_url).to_return(body: user_options.merge({id: 1}).to_json)

    user = User.create(user_options)
    assert(user.age == 18, "user's age was not 18")
    assert(user.id == 1, "user doesn't have an id")
    assert(user.created_at, "created_at is nil")
    assert(user.updated_at, "updated_at is nil")
  end

  def test_destroys
    user = build_user 1
    stub_request(:delete, "#{User.arkenstone_url}#{user.id}").to_return(status: 200)
    result = user.destroy
    assert(result == true, "delete was not true")
  end

  def test_update_attributes
    stub_request(:post, User.arkenstone_url).to_return(body: user_options.merge({id: 1}).to_json)

    user = User.create(user_options)

    stub_request(:put, "#{User.arkenstone_url}#{user.id}").to_return(body: user_options.merge({id: 1, name: 'Jack Doe', age: 24}).to_json)

    user.update_attributes({name: 'Jack Doe', age: 24})
    assert(user.name == 'Jack Doe', 'user#name is not eq Jack Doe')
    assert(user.age == 24, 'user#age is not eq 24')
  end

  def test_update_attribute
    stub_request(:post, User.arkenstone_url).to_return(body: user_options.merge({id: 1}).to_json)

    user = User.create(user_options)

    stub_request(:put, "#{User.arkenstone_url}#{user.id}").to_return(body: user_options.merge({id: 1, name: 'Jack Doe'}).to_json)

    user.update_attribute 'name', 'Jack Doe'
    assert(user.name == 'Jack Doe', 'Jack doe is not alive')

    stub_request(:put, "#{User.arkenstone_url}#{user.id}").to_return(body: user_options.merge({id: 1, name: 'Jacked Doe'}).to_json)
    user.update_attribute :name, 'Jacked Doe'
    assert(user.name == 'Jacked Doe', 'Jack is not Jacked')
  end

  def test_where_by_name
    user1 = create_user(user_options(name: 'user1'), 1)
    user2 = create_user(user_options(name: 'user2'), 2)
    user3 = create_user(user_options(age: 42), 3)

    users = User.where(age: nil)
    assert users.include(user1), "\nExpected users to include: #{user1}\nGot: #{users}"
    assert users.include(user2), "\nExpected users to include: #{user2}\nGot: #{users}"
  end
end

def build_user(id)
  User.build user_options.merge({id: id})
end

def create_user(options, id)
  stub_request(:post, User.arkenstone_url).to_return(body: options.merge({id: id}).to_json)
  User.build(options).save
end

def user_options(options={})
  {name: 'John Doe', age: 18, gender: 'Male', bearded: true}.merge!(options)
end
