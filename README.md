# Capybara::Workflows

Organise your Capybara helper library into by-role workflow sets or [page objects](https://code.google.com/p/selenium/wiki/PageObjects).

Helpers are executed by the original Capybara session, which you provide by dependency injection, as if you'd written the code where you call the method. All your usual helpers are available.

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
MemberWorkflows.new(self).log_in(email, password)
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


### Cucumber

```ruby
Then(/^my teacher can't monitor my progress$/) do
  GroupManagerWorkflows.new(self).view_student_progress(@member.email)
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
    MemberWorkflows.new(self).login_with(member.email, member.password)
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

## Contributing

1. Fork it ( https://github.com/nruth/capybara-workflows/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
