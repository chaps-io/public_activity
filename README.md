# PublicActivity

public_activity provides smooth acitivity tracking for your ActiveRecord models in Rails 3.
Simply put: it records what has been changed or edited and gives you the ability to present those recorded activities to users - in a similar way Github does it.

## Example

A picture is worth a thousand words, so here is a visual representation of what this gem is about:

![Example usage](http://i.imgur.com/uGPSm.png)

## Installation

You can install this gem as you would any other gem:
    gem install public_activity
or in your Gemfile:
    gem 'public_activity'

## Usage

Create migration for activities (in your Rails project):
    rails g public_activity:migration
    rake db:migrate

Add 'tracked' to the model you want to keep track of:
    class Article < ActiveRecord::Base
      tracked
    end
And now, by default create/update/destroy activities are recorded in activities table. 
To display them you can do a simple query:
    # some_controller.rb
    def index
      @activities = PublicActivity::Activity.all
    end
And in your views:
    <% for activity in @activities %>
      <%= activity.text %><br/>
    <% end %>
The only thing left is to add translations to your locale files, for example:
    en:
      activity:
        article:
          create: 'Article has been created'
          update: 'Someone has edited the article'
          destroy: 'Some user removed an article!'

This is only a basic example, refer to documentation for more options and customization!
## Documentation

You can find documentation [here](http://rubydoc.info/gems/public_activity/)

## License
Copyright (c) 2011 Piotrek Okoński, released under the MIT license
