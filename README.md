# Lev

Rails is fantastic and obviously super successful.  Lev is an attempt to improve Rails by:

1. Providing a better, more structured, and more organized way to implement code features
2. De-emphasizing the "model is king" mindset when appropriate

Rails' MVC-view of the world is very compelling and provides a sturdy scaffold with which to create applications quickly.  However, sometimes it can lead to business logic code getting a little spread out.  When trying to figure out where to best put business logic, you often hear folks recommending "fat models" and "skinny controllers".  They are saying that the business logic of your app should live in the model classes and not in the controllers.  I agree that the logic shouldn't live in the controllers, but I also argue that it shouldn't always live in the models either, especially when that logic touches multiple models.

When all of the business logic lives in the models, some bad things can happen:

1. your models can become bloated with code that only applies to certain features
2. your models end up knowing way too much about other models, sometimes multiple hops away
3. your business logic gets spread all over the place.  The execution of one "feature" can jump between bits of code in multiple models, their various ActiveRecord life cycle callbacks (before_create, etc), and their associated observers.

Lev introduces "routines" which you can think of as pieces of code that have all the responsibility for making one thing (use case) happen, e.g. "add an email to a user", "register a student to a class", etc).  

Routines...

1. Can call other routines
2. Have a common error reporting framework
3. Run within a single transaction with a controllable isolation level

Handlers are specialized routines that take user input (e.g. form data) and then take an action based on that input.  

Handlers...

1. Help you verify that the calling user is authorized to run the handler
2. Provide ways to validate incoming parameters in a very ActiveModel-like way (even when the parameters are not associated with a model)
3. Integrate will with basic routines

In a Lev-oriented Rails app, controllers are just responsible for connecting routes to Handlers.  In fact, controller methods just end up being calls to ```handle_with(MyHandler)```, ```handle_with``` being a helper method provided by Lev.  

Lev also provides a ```lev_form_for``` form builder to replace ```form_for```.  This builder integrates well with the error reporting infrastructure in routines and handlers, and in general is a nice way to get away from forms that are very single-model-centric.

When using Lev, model classes have the following responsibilities:


1. Hook into the ORM (i.e., inherit from ActiveRecord::Base)
2. Establish relationships to other models (e.g. belongs_to, has_many, including dependent: :destroy)
3. Validate internal state
    1. Do not validate state in related models
    2. Can validate the presence of relationship (can check that a foreign key is present)
4. Can perform queries when those queries only use internal model state and are aware of internal model state (e.g. arguments to queries should be in the language of the model state)
5. Can create records when those creations only need values internal to this model and take arguments in the language of the internal model state.

The result of the principles above and below, model classes end up being very small.  This is good because a lot of code depends on the models and having the be small normally means they are also stable.

## Installation

Add this line to your application's Gemfile:

    gem 'lev'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lev

## Usage

For the moment, details on how to use lev live in big sections of comments at the top of:

* https://github.com/lml/lev/blob/master/lib/lev/routine.rb
* https://github.com/lml/lev/blob/master/lib/lev/handler.rb
* https://github.com/lml/lev/blob/master/lib/lev/handle_with.rb
* https://github.com/lml/lev/blob/master/lib/lev/form_builder.rb

TBD: talk about ```delegate_to_routine```.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
