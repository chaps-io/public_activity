require 'test_helper'

describe PublicActivity::Common do
  before do
    @owner     = User.create(:name => "Peter Pan")
    @recipient = User.create(:name => "Bruce Wayne")
    @options   = {:params => {:author_name => "Peter",
                  :summary => "Default summary goes here..."},
                  :owner => @owner}
  end
  subject { article(@options).new }

  it 'uses global fields' do
    subject.save
    activity = subject.activities.last
    activity.parameters.must_equal @options[:params]
    activity.owner.must_equal @owner
  end

  it 'inherits instance parameters' do
    subject.activity :params => {:author_name => "Michael"}
    subject.save
    activity = subject.activities.last

    activity.parameters[:author_name].must_equal "Michael"
  end

  it 'accepts instance recipient' do
    subject.activity :recipient => @recipient
    subject.save
    subject.activities.last.recipient.must_equal @recipient
  end

  it 'accepts instance owner' do
    subject.activity :owner => @owner
    subject.save
    subject.activities.last.owner.must_equal @owner
  end

  it 'accepts owner as a symbol' do
    klass = article(:owner => :user)
    article = klass.new(:user => @owner)
    article.save
    activity = article.activities.last

    activity.owner.must_equal @owner
  end

  describe '#extract_key' do
    describe 'for class#activity_key method' do
      before do
        @article = article(:owner => :user).new(:user => @owner)
      end

      it 'assigns key to value of activity_key if set' do
        def @article.activity_key; "my_custom_key" end

        @article.extract_key(:create, {}).must_equal "my_custom_key"
      end

      it 'assigns key based on class name as fallback' do
        def @article.activity_key; nil end

        @article.extract_key(:create).must_equal "article.create"
      end

      it 'assigns key value from options hash' do
        @article.extract_key(:create, :key => :my_custom_key).must_equal "my_custom_key"
      end
    end

    describe 'for camel cased classes' do
      before do
        class CamelCase < article(:owner => :user)
          def self.name; 'CamelCase' end
        end
        @camel_case = CamelCase.new
      end

      it 'assigns generates key from class name' do
        @camel_case.extract_key(:create, {}).must_equal "camel_case.create"
      end
    end
  end

  # no key implicated or given
  specify { ->{subject.prepare_settings}.must_raise PublicActivity::NoKeyProvided }

  describe 'resolving values' do
    it 'allows procs with models and controllers' do
      context = mock('context')
      context.expects(:accessor).times(2).returns(5)
      controller = mock('controller')
      controller.expects(:current_user).returns(:cu)
      PublicActivity.set_controller(controller)
      p = proc {|controller, model|
        assert_equal :cu, controller.current_user
        assert_equal 5, model.accessor
      }
      PublicActivity.resolve_value(context, p)
      PublicActivity.resolve_value(context, :accessor)
    end
  end

end
