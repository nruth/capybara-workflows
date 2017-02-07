Don't use this. Just use SimpleDelegator instead.

```ruby
class SomeModule::TestHelpers < SimpleDelegator
  def go_to_tutorials_index_page
    visit x_path
    click "y"
    _check_index_page
  end
  
  private
  def _check_index_page
    expect z
  end
end
```

Then in rspec/capybara session:
```
RSpec.describe "something" do 
  let(:test_helper) { SomeModule::TestHelpers.new(self) }
  
  specify "and another thing" do
    test_helper.go_to_tutorials_index_page
  end
end
```
