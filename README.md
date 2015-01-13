# Capybara::Workflows

Organise your Capybara helper library into by-role workflow sets or [page objects](https://code.google.com/p/selenium/wiki/PageObjects).

Helpers are executed by the original Capybara session, which you provide by dependency injection, as if you'd written the code where you call the method. All your usual helpers are available.

## Examples / quickstart

```ruby
specify 'I can enter my qualifications' do
  qualifications = QualificationWorkflows.new(self)
  qualifications.add_course 'GCSE', 'Maths', 'A', 'Predicted'
  qualifications.add_course 'A2', 'Other', 'A*', '2010'
  qualifications.add_course 'AS', 'Chemistry', 'B', '2011'
  expect(page).to have_css('tr', text: 'GCSE Maths A Predicted')
  expect(page).to have_css('tr', text: 'A2 Other A* 2010')
  expect(page).to have_css('tr', text: 'AS Chemistry B 2011')
end
```

Where you have defined the QualificationWorkflows class and its #add_course method as explained below.

Workflow class copy-paste templates/skeletons to get you started

```ruby
class MemberWorkflows < Capybara::Workflows::WorkflowSet
  # sign in
  workflow :login_with do |email, password|
    visit '/member'
    fill_in("member_email", :with => email)  
    fill_in("member_password", :with => password)
    click_button("member_submit")
  end

  workflow :logout do
    visit '/member'
    click_on "Sign out"
  end
end

# or with instance variables 

class MemberWorkflows < Capybara::Workflows::WorkflowSet
  attr_accessor :logged_in, :email, :password
  def initialize(session, email, password)
    self.email = email
    self.password = password
    self.logged_in = false
    super(session)
  end

  # sign in
  workflow :login do |workflow|
    unless workflow.logged_in
      visit '/member'
      fill_in("member_email", with: workflow.email)
      fill_in("member_password", with: workflow.password)
      click_button("member_submit")
      workflow.logged_in = true
    end
  end
end
```


## Installation

Add to your Gemfile's test group:

```ruby
gem 'capybara-workflows'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capybara-workflows

## Usage

How you group things is up to you. This could have been called Capybara::PageObjectModel instead, but I wasn't grouping them that way at time of writing, and don't want to stand on [site_prism's](https://github.com/natritmeyer/site_prism) toes.

That is to say, rather than having classes like

```ruby
MemberWorkflows.new(self, email, password).log_in
```

you could instead have

```ruby
MemberLoginPage.new(self).log_in(email, password)
```

or whichever structure you care to think of.

All this actually does is enable you to write lines of capybara test code in another class, and share it between test files, reducing LOC and increasing sharing.

The trick is executing that code in the context of the capybara session, not the object holding the helpers. That's why you pass the session in when initialising the object, and why you write workflow blocks rather than method definitions.


### Defining workflows

For simplicity you may want to start writing these class definitions directly into your test files, just to get started. See Loading workflows for some ideas how to reorganise later.

```ruby
class MemberWorkflows < Capybara::Workflows::WorkflowSet
  # sign in
  workflow :login_with do |email, password|
    visit '/member'
    fill_in("member_email", :with => email)  
    fill_in("member_password", :with => password)
    click_button("member_submit")
  end

  workflow :logout do
    visit '/member'
    click_on "Sign out"
  end
end
```

Here's something a little more complex, which tracks previous logins (if made through the same object's interface). The optional workflow parameter gives access to instance variables and other workflow definitions. It's passed to your block as its final argument.

```ruby
class MemberWorkflows < Capybara::Workflows::WorkflowSet
  attr_accessor :logged_in, :email, :password
  def initialize(session, email, password)
    self.email = email
    self.password = password
    self.logged_in = false
    super(session)
  end

  # sign in
  workflow :login do |workflow|
    unless workflow.logged_in
      visit '/member'
      fill_in("member_email", with: workflow.email)
      fill_in("member_password", with: workflow.password)
      click_button("member_submit")
      workflow.logged_in = true
    end
  end

  workflow :logout do |workflow|
    visit '/member'
    click_on "Sign out"
    workflow.logged_in = false
  end

  workflow :post_article do |title, body, workflow|
    workflow.login unless workflow.logged_in
    visit new_article_path
    fill_in "Title", with: title
    fill_in "Body", with: body
    click_on "Post article"
  end
end
```



### Cucumber

Below demonstrates using workflows to help manage state between steps.

```ruby
Given(/^I am in a group$/) do
  @group = member.groups.make
  gm = @group.group_managers.make
  @group_manager = GroupManagerWorkflows.new(self, gm.email, gm.password)
end

Then(/^my teacher can't monitor my progress$/) do
  @group_manager.view_student_progress(@member.email)
  expect(page).to have_content("has not given you permission to monitor their progress. Please ask them to add you to their supervisor list in their account settings page.")
end

or

When(/^I go to my account page$/) do
  MemberWorkflows.new(self).login_with(@member.email, @member.password)
  ensure_on edit_member_path
end
```

### RSpec

```ruby
describe "doing stuff" do
  let(:member) {Member.make}
  before(:each) do
    MemberWorkflows.new(self).login_with(@member.email, @member.password)
  end
end
```

### Loading workflows

Define workflow classes in spec/support, feature/support, or whichever directory you prefer that will be loaded before your tests run. Or require them explicitly in your tests.

One approach is to put the following snippet into spec/support/load_shared_test_lib.rb for RSpec, and features/support/load_shared_test_lib.rb for Cucumber

```ruby
  # -*- encoding : utf-8 -*-
  Dir[
    File.expand_path(
      Rails.root.join 'test_helper_lib', '**', '*.rb'
    )
  ].each {|f| require f}
```

We use:

```
-|
 |- feature
 |- spec
 |- test_helper_lib
   |- workflows
     |- member_workflows.rb
     |- etc
```

## State encapsulation

Managing state, or context of execution, with shared cucumber steps is not fun. Assigning workflow objects to ivars and letting them track who is logged in, what their attributes are, what they can do, etc, may ease the pain.

For RSpec state encapsulation may or may not be useful, since test statements share scope and are typically easier to manage than Cucumber. However, when sharing with Cucumber it may be simpler to reuse identical workflows.

## Contributing

1. Fork it ( https://github.com/nruth/capybara-workflows/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
