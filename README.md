# Lev

Lev is an attempt to improve Rails by:

1. Providing a better, more structured, and more organized way to implement code features
2. De-emphasizing the "model is king" mindset when appropriate

Rails' MVC-view of the world is very compelling and provides a sturdy scaffold with which to create applications quickly.  However, sometimes it can lead to business logic code getting a little spread out.  When trying to figure out where to best put business logic, you often hear folks recommending "fat models" and "skinny controllers".  They are saying that the business logic of your app should live in the model classes and not in the controllers.  While it is a good idea that logic not live in the controllers, it shouldn't always live in the models either, especially when that logic touches multiple models.

When all of the business logic lives in the models, some bad things can happen:

1. your models can become bloated with code that only applies to certain features
2. your models end up knowing way too much about other models, sometimes multiple hops away
3. your business logic gets spread all over the place.  The execution of one "feature" can jump between bits of code in multiple models, their various ActiveRecord life cycle callbacks (before_create, etc), and their associated observers.

Lev introduces two main constructs to get around these issues: **Routines** and **Handlers**.

## Routines

Lev's Routines are pieces of code that have all the responsibility for making one thing (one use case) happen, e.g. "add an email to a user", "register a student to a class", etc), normally acting on objects from more than one model.

Routines...

1. Can call other routines
2. Have a common error reporting framework
3. Run within a single transaction with a controllable isolation level

In an OO/MVC world, an operation that involves multiple objects might be implemented by spreading that logic among those objects.  However, that leads to classes having more responsibilities than they should (and more knowlege of other classes than they should) as well as making the code hard to follow.

Routines typically don't have any persistent state that is used over and over again; they are created, used, and forgotten.  A routine is a glorified function with a special single-responsibility purpose.

A class becomes a routine by calling `lev_routine` in its definition, e.g.:

    class MyRoutine
      lev_routine
      ...

Other than that, all a routine has to do is implement an "exec" method (typically `protected`) that takes arbitrary arguments and that adds errors to an internal array-like "errors" object and outputs to a "outputs" hash.  Two convenience methods are provided for adding errors:

Errors can be recorded in a number of ways.  You can manually add errors to the built-in `errors` object:

    errors.add(true, code: :search_terms_incorrect)

The first parameter to the `add` call says whether or not the error should be fatal for the running of the routine (no more work should be done and the transaction should be rolled back).  Otherwise, the arguments after that are a hash that can contain values for the following keys:

* `:code` A symbol indicating the kind of error that occurred
* `:data` Any data that is useful for understanding the error (`:code`-specific)
* `:kind` If you don't set this, it will default to `:lev` for Lev-generated errors, and `:activerecord` for ActiveRecord-generated errors
* `:message` A human-readable error message
* `:offending_inputs` An array of symbols indicating which inputs caused the error (if any); if there is only one symbol, you can specify it as a lone symbol instead of a symbol in a one-element array.

Two convenience methods are also provided for adding errors: `fatal_error` and `nonfatal_error`. These have the same interface as `errors#add` except they provide the first `is_fatal` boolean argument for you.  In its current implementation, `nonfatal_error` may still cause a routine higher up in the execution hierarchy to halt running.

Here's an example setting an error and an output:

    class MyRoutine
      lev_routine

    protected
      def exec(foo, options={})  # whatever arguments you want here
        fatal_error(code: :some_code_symbol) if foo.nil?
        outputs[:bar] = foo * 2
      end
    end

If you'd like the `fatal_error` to raise a `StandardError` immediately instead of bubbling up to the `Lev::Routine#errors` object, you must configure it:

```ruby
Lev.configure do |config|
  config.raise_fatal_errors = true
end
```

So if you `fatal_error(name: :is_blank)` it will raise `StandardError: "name is blank"`, or `fatal_error(thing: :is_broken, and: :messed_up)` it will raise `StandardError: "thing is broken - and messed up"`

You can override the global setting in your routine, which also overrides nested routine settings:

```ruby
# initializer
Lev.configure do |config|
  config.raise_fatal_errors = false
end

# app/routines/my_routine.rb
class MyRoutine
  lev_routine raise_fatal_errors: true

  uses_routine Tasks::MyTaskRoutine # Still raises despite its setting
end


# app/subroutines/tasks/my_task_routine.rb
module Tasks
  class MyTaskRoutine
    lev_routine raise_fatal_errors: false
  end
end
```


Additionally, see below for a discussion on how to transfer errors from ActiveRecord models.

Any `StandardError` raised within a routine will be caught and transformed into a fatal error with `:kind` set to `:exception`.  The caller of this routine can choose to reraise this exception by calling `reraise_exception!` on the returned errors object:

    result = MyRoutine.call(42)
    result.errors.reraise_exception! # does nothing if there were no exception errors

Relatedly, a convenience method is provided if the caller wants to raise an exception if there were any errors returned (whether or not they themselves were caused by an exception)

    result = MyRoutine.call(42)
    result.errors.raise_exception_if_any!(MyFavoriteError)

By default `raise_exception_if_any!` will raise a `StandardError` with a message containing the concatenated messages of the errors.  You can pass a different exception class to this method to use something other than `StandardError`.

A routine will automatically get both class- and instance-level `call`
methods that take the same arguments as the `exec` method.  The class-level
call method simply instantiates a new instance of the routine and calls
the instance-level call method (side note here is that this means that
routines aren't typically instantiated with state).

When called, a routine returns a `Result` object, which is just a simple wrapper
of the outputs and errors objects.

    result = MyRoutine.call(42)
    puts result.outputs[:bar]    # => 84


### Nesting Routines

As mentioned above, routines can call other routines.  While this is of course possible just by calling the other routine's call method directly, it is strongly recommended that one routine call another routine using the provided `run` method.  This method takes the name of the routine class and the arguments/block it expects in its call/exec methods.  By using the `run` method, the called routine will be hooked into the common error and transaction mechanisms.

When one routine is called within another using the `run` method, there is only one transaction used (barring any explicitly made in the code) and its isolation level is sufficiently strict for all routines involved.

It is highly recommend, though not required, to call the `uses_routine` method to let the routine know which subroutines will be called within it.  This will let a routine set its isolation level appropriately, and will enforce that only one transaction be used and that it be rolled back appropriately if any errors occur.

Once a routine has been registered with the `uses_routine` call, it can be run by passing run the routine's Class or a symbol identifying the routine.  This symbol can be set with the `:as` option.  If not set, the symbol will be automatically set by converting the routine class' full name to a symbol. e.g:

    uses_routine CreateUser
                 as: :cu

and then you can call this routine with any of the following:

* `run(:cu, ...)`
* `run(:create_user, ...)`
* `run(CreateUser, ...)`
* `CreateUser.call(...)`  (not recommended)

#### Errors from Nested Routines

`uses_routine` also provides a way to specify how errors relate to routine
inputs. Take the following example.  A `User` model calls `Routine1` which calls
`Routine2`.

    User --> Routine1.call(foo: "abcd4") --> Routine2.call(bar: "abcd4")

An error occurs in `Routine2`, and Routine2 notes that the error is related
to its `bar` input.  If that error and its metadata bubble up to the `User`,
the `User` won't have any idea what `bar` relates to -- the `User` only knows
about the interface to `Routine1` and the `foo` parameter it gave it.

`Routine1` knows that it will call `Routine2` and knows what its interface is.  It can then specify how to map terminology from `Routine2` into `Routine1`'s context.  E.g., in the following class:

    class Routine1
      lev_routine
      uses_routine Routine2,
                   translations: {
                     inputs: { map: {bar: :foo} }
                   }
      def exec(options)
        run(Routine2, bar: options[:foo])
      end
    end

`Routine1` notes that any errors coming back from the call to `Routine2` related to `:bar` should be transfered into `Routine1`'s errors object as being related to `:foo`.  In this way, the caller of `Routine1` will see errors related to the arguments he understands.

In addition to the `map:` configuration for input transferral, there are three other configurations:

1. **Scoped** - Appends the provided scoping symbol (or symbol array) to the input symbol.

    `{scope: SCOPING_SYMBOL_OR_SYMBOL_ARRAY}`

    e.g. with `{scope: :register}` and a call to a routine that has an input
    named `:first_name`, an error in that called routine related to its
    `:first_name` input will be translated so that the offending input is
    `[:register, :first_name]`.

2. **Verbatim** - Uses the same term in the caller as the callee.

     `{type: :verbatim}`

3. **Mapped** - Give an explicit, custom mapping:

     `{map: {called_input1: caller_input1, called_input2: :caller_input2}}`

4. **Scoped and mapped** - Give an explicit mapping, and also scope the
     translated terms.  Just use `scope:` and `map:` from above in the same hash.

If an input translation is unspecified, the default is scoped, with `SCOPING_SYMBOL_OR_ARRAY` equal to the `as:` option passed to `uses_routine`, if provided, or if that is not provided then the symbolized name of the routine class.  E.g. for:

    class MyRoutine
      lev_routine
      uses_routine OtherRoutine, as: :jimmy

an errors generated on the `foo` input in `OtherRoutine` will be transferred up to `MyRoutine` with a `[:jimmy, :foo]` scope.  If the `as: :jimmy` option were not specified, the transferred error would have a `[:other_routine, :foo]` scope.

Via the `uses_routine` call, you can also ignore specified errors that occur
in the called routine. e.g.:

    uses_routine DestroyUser,
                 ignored_errors: [:cannot_destroy_non_temp_user]

ignores errors with the provided code.  The `ignore_errors` key must point
to an array of code symbols or procs.  If a proc is given, the proc will
be called with the error that the routine is trying to add.  If the proc
returns true, the error will be ignored.


#### Outputs from Nested Routines

In addition to errors being transferred from subroutines to calling routines, a subroutine's outputs are also automatically transferred to the calling routine's "outputs" hash.  Exactly how they are transferred is configurable with the same 4 options as input transferals, e.g.:

    class Routine1
      lev_routine
      uses_routine Routine2,
                   translations: {
                     outputs: { type: :verbatim }
                   }

      def exec(options)
        run(Routine2, bar: options[:foo])
        # Assuming Routine2 generates an output named "x", then outputs[:x] will be
        # available as of this line
      end
    end

If the output translations are not specified, they will be scoped exactly like how input translations are scoped by default.


Note if multiple outputs are transferred into the same named output (e.g. by calling the same routine over and over in a loop), an array of those outputs will be stored under that name.

#### Overriding `uses_routine` Options

Any option passed to uses_routine can also be passed directly to the run
method.  To achieve this, pass an array as the first argument to "run".
The array should have the routine class or symbol as the first argument,
and the hash of options as the second argument.  Options passed in this
manner override any options provided in uses_routine (though those options
are still used if not replaced in the run call).  For example:

    class ARoutine
      lev_routine
      uses_routine BRoutine

    protected
      def exec(...)
        run([ BRoutine, {translations: {outputs: {type: :verbatim}}} ])
      end
    end

### transfer_errors_from


When errors are captured inside an `ActiveRecord` errors object, you can use `transfer_errors_from` to pull them into the routine errors object.  This method takes three arguments:

1. The ActiveRecord instance that may have errors to transfer.
2. A hash describing how to map the error message, using the same options passed to the input translations in a `uses_routine` call, e.g. `transfer_errors_from(myModel, {type: :verbatim})`.
3. A flag that if `true` will cause the routine to fail fatally if there are any errors transferred.

### Specifying Transaction Isolations

A routine is automatically run within a transaction.  The isolation level of the routine can be set by passing a `:transaction` option to the `lev_routine` call (or to the `lev_handler` call, if appropriate).  The value must be one of the following:

* `:no_transaction`
* `:read_uncommitted`
* `:read_committed`
* `:repeatable_read`
* `:serializable`

Note that by setting an isolation level, you are stating the minimum isolation level at which a routine must be run.  When routines are nested inside each other, the highest-specified isolation level from any one of them is used in the one transaction in which all of a routines' subroutines run.

For example, if you write a routine that does a complex query, you might not need any transaction:

    class MyQueryRoutine
      lev_routine transaction: :no_transaction

If unspecified, the default isolation is `:repeatable_read`.

### delegate_to_routine

Sometimes you'll want to override standard ActiveRecord methods in a model so that they use a routine instead of the default implementation. For this, inside of that ActiveRecord model you can call the class method `delegate_to_routine`, which takes two key-value pairs:

1. `:method` A symbol for the instance method to override (e.g. `:destroy`)
2. `:options` A hash of options including:
    * `:routine_class` The class of the routine to delegate to; if not given, the class is autocomputed by concatenating the provided `:method` with the model class name.

When `delegate_to_routine` is called, the provided method will call the routine and the overriden method will be aliased to the original name with `_original` appended to it.  For example:

    class Product < ActiveRecord::Base
      delegate_to_routine method: :destroy
    end

will alias the old `destroy` method as `destroy_original` and add a new `destroy` method that calls the `DestroyProduct` routine.

### Express Calling of Routines

Routines commonly return one output.  These routines are often named things like `GetUserEmail` or `IsFinalized`.  Particularly
for boolean queries like `IsBlahBlah`, it is onerous to say:

```ruby
if IsBlahBlah.call(arg1, arg2).outputs.some_output_containing_the_true_false_value
```

As a convenience, routines can be called "expressly" (as in compactly) using the bracket operator.  For example with the
following routine:

```ruby
class AreArgumentsEqual
  lev_routine

  def exec(arg1, arg2)
    outputs[:are_arguments_equal] = (arg1 == arg2)
  end
end
```

you could call it in the normal way:

```ruby
if AreArgumentsEqual.call(201, 202).outputs.are_arguments_equal
  # do something
end
```

or you can call it using brackets:

```ruby
if AreArgumentsEqual[201, 202]
  # do something
end
```

When using this bracket style of calling routines, Lev assumes that the value to be returned is named with the underscored
version of the routine name, e.g. `AreArgumentsEqual` has a default return value of `are_arguments_equal`.  Module names
are disregarded when computing the default name.

The `express_output` can be overriden:

```ruby
class AreArgumentsEqual
  lev_routine, express_output: :answer

  def exec(arg1, arg2)
    outputs[:answer] = (arg1 == arg2)
  end
end
```

When calling with the bracket operator, any errors accumulated by the routine are raised in an exception (have to do this
since you have no other way to pay attention to the errors).

### Delegates

If you have

```ruby
class BarRoutine
  lev_routine

  def exec(alpha:, beta:)
    # Do work
  end
end
```

you might have a reason to wrap this routine inside another, in which case you could write:

```ruby
class FooRoutine
  lev_routine

  uses_routine BarRoutine,
               translations: {
                 outputs: { type: :verbatim },
                 inputs: { type: :verbatim }
               }

  def exec(alpha:, beta:)
    run(BarRoutine, alpha: alpha, beta: beta)
  end
end
```

or if you use the `delegates_to:` shortcut, you can instead equivalently wrap `BarRoutine` with:

```ruby
class ShorterFooRoutine
  lev_routine delegates_to: BarRoutine
end
```

When using `delegates_to`, any `express_output` value set in the delegated routine is automatically
used again by the delegating routine.

### Other Routine Methods

Routine class have access to a few other methods:

1. a `runner` accessor which points to the routine which called it. If
   runner is nil that means that no other routine called it (some other
   code did)
2. a `topmost_runner` accessor which points to the highest routine in the calling
   hierarchy (that routine whose 'runner' is nil)

### Calling routines as ActiveJobs

If `ActiveJob` is included in your project, you can invoke a routine to be run in the background.  E.g. instead of saying

```ruby
MyRoutine.call(arg1: 23, arg2: 'howdy')
```

You can say

```ruby
MyRoutine.perform_later(arg1: 23, arg2: 'howdy')
```

By default jobs are placed in the `:default` queue, but you can override this in the `lev_routine` call:

```ruby
class MyRoutine
  lev_routine active_job_queue: :some_other_queue
end
```

## Handlers

Handlers are specialized routines that take user input (e.g. form data) and then take an action based on that input.  Because all Handlers are Routines, everything discussed above applies to them.

Handlers...

1. Help you verify that the calling user is authorized to run the handler
2. Provide ways to validate incoming parameters in a very ActiveModel-like way (even when the parameters are not associated with a model)
3. Can call other Routines using `uses_routine` and `run`
4. Map one-to-one with controller actions; by keeping the logic in each controller action encapsulated in a Handler, the code becomes independently-testable and also prevents the controller from being "fat" with 7 different actions all containing disparate logic touching different models.

A class becomes a handler by calling `lev_handler` in its definition, e.g.:

    class MyHandler
      lev_handler
      ...

Additionally, a handler **must** implement two instance methods:

1. `handle`, which takes no arguments and does the work the handler is charged with
2. `authorized?`, which returns true if and only if the caller is authorized to do what the handler is charged with

Handlers **may**...

1. implement the `setup` instance method which runs before `authorized?` and `handle`. This method can do anything, and will likely include setting up some instance objects based on the params.
2. call the class method `paramify` to declare, cast, and validate parts of the params hash.  See below for more on this.

Any options passed in to a handler's `call` method are made available within the handler via an `options` attribute.  If this options hash includes values for `:params`, `:caller`, and `:request` these values will be available within the code you write by accessors with the same names.  These values are expected to contain the request params, the caller (whatever your application defines as `current_user`), and the entire HTTP request.  See the `handle_with` method below for an easy way to pass these options to your handler.

Additionally, the handler provides attributes to return the `errors` object and the `results` object.

The `handle` method that you define should not return anything; they just set values in the errors and results objects.  The documentation for each handler should explain what the results will be and any nonstandard data required to be passed in in the options.

In addition to the class- and instance-level `call` methods provided by Lev::Routine, Handlers have a class-level `handle` method (an alias of the class-level `call` method).  The convention for handlers is that the `call` methods (and this class-level `handle` method) take a hash of options/inputs.  The instance-level `handle` method doesn't take any arguments since the arguments have been stored as instance variables by the time the instance-level handle method is called.

  Example:

    class MyHandler
      lev_handler
    protected
      def authorized?
        # return true iff exec is allowed to be called, e.g. might
        # check the caller against the params
      def handle
        # do the work, add errors to errors object and results to the results hash as needed
      end
    end

### paramify

By declaring one or more `paramify` blocks in a handler, you can declare, group, cast, and validate parts of the `params` hash.  Think of `paramify` as a way to declare an ad-hoc `ActiveModel` class to wrap incoming parameters.  Normally, you only get easy validation of input parameters when those parameters are passed to an application model that is validated during a save.  `paramify` lets you do this for any arbitrary collection of incoming parameters without requiring those parameters to live in application models.

The first argument to `paramify` is the key in params which points to a hash of params to be paramified.  If this first argument is unspecified (or specified as `:paramify`, a reserved symbol), the entire params hash will be paramified.  The block passed to paramify looks just like the guts of an ActiveAttr model.

For example, when the incoming params includes :search => {:type, :terms, :num_results}, the `paramify` block might look like:

    paramify :search do
      attribute :type, type: String
      validates :type, presence: true,
                       inclusion: { in: %w(Name Username Any),
                                    message: "is not valid" }

      attribute :terms, type: String
      validates :terms, presence: true

      attribute :num_results, type: Integer
      validates :num_results, numericality: { only_integer: true,
                                              greater_than_or_equal_to: 0 }
    end

This will result in a `search_params` variable being available.  `search_params.num_results` would be guaranteed to be an integer greater than or equal to zero.  Note that if you want to use a "Boolean" type, you need to type it with a lowercase (`type: boolean`).

The following is a more complete example using the `paramify` block above:

    class MyHandler
      lev_handler

      paramify :search do
        attribute :type, type: String
        validates :type, presence: true,
                         inclusion: { in: %w(Name Username Any),
                                      message: "is not valid" }

        attribute :terms, type: String
        validates :terms, presence: true

        attribute :num_results, type: Integer
        validates :num_results, numericality: { only_integer: true,
                                                greater_than_or_equal_to: 0 }
      end

      def handle
        # By this time, if there were any errors the handler would have
        # already populated the errors object and returned.
        #
        # Paramify makes a 'search_params' attribute available through
        # which you can access the paramified params, e.g.
        x = search_params.num_results
        ...
      end
    end

### handle_with

`handle_with` is a utility method for calling handlers from controllers.  To use it, call `include Lev::HandleWith` in your relevant controllers (or in your ApplicationController):

    class ApplicationController
      include Lev::HandleWith
      ...
    end

Then, call `handle_with` from your various controller actions, e.g.:

    handle_with(MyFormHandler,
                params: params,
                success: lambda { redirect_to 'show', notice: 'Success!'},
                failure: lambda { render 'new', alert: 'Error' })

`handle_with` takes care of calling the handler and populates a `@handler_result` object with results and errors from running the handler.

The 'success' and 'failure' lambdas are called if there aren't or are errors, respectively.  Alternatively, if you supply a 'complete' lambda, that lambda will be called regardless of whether there are any errors.  Inside these lambdas (and inside the views they connect to), the @handler_outcome variable containing the errors and results from the handler will be available.

Specifying 'params' is optional.  If you don't specify it, `handle_with` will use the entire params hash from the request.

Handlers help us clean up controllers in our Rails projects.  Instead of having a different piece of application logic in every controller action, a Lev-oriented app's controllers just end up being responsible for connecting routes to handlers, normally via a quick call to `handle_with`.

### lev_form_for

Lev also provides a `lev_form_for` form builder to replace `form_for`.  This builder integrates well with the error reporting infrastructure in routines and handlers, and in general is a nice way to get away from forms that are very single-model-centric.

The first argument passed to `lev_form_for` is a symbol that scopes the form fields.  In a normal `form_for`, the `:url` for the form is autodetermined based on the model instance passed in; since there is no model for `lev_form_for`, you'll need to specify the `:url` option.  Beyond that, any options you can pass to `form_for` you can pass to `lev_form_for`.

Consider the following example:

    <%= lev_form_for :register, url: '/users/register', html: {id: 'register-form'} do |f| %>
      <p>Please choose a username and password.</p>

      <label>Username</label>
      <%= f.text_field :username %>

      <label>First Name</label>
      <%= f.text_field :first_name %>

      <label>Password</label>
      <%= f.password_field :password %>

      <label>Password (again)</label>
      <%= f.password_field :password_confirmation %>

      <%= f.submit "Register", id: "register_submit" %>
    <% end %>

Here, the form parameters will include

    :register => {:username => 'bob79', :first_name => 'Bob', :password => 'password', :password_confirmation => 'password'}

A route could direct the URL above to a controller action:

    post '/users/register', to: 'users#register'

The `UsersController` could then connect this route to a handler:

    class UsersController < ApplicationController
      include Lev::HandleWith

      def register
        handle_with(UsersRegister,
                    success: lambda { redirect_to root_path },
                    failure: lambda { render :new })
      end
    end

And then the `UsersRegister` handler would exist to process the form parameters and take action.

    class UsersRegister
      lev_handler

      paramify :register do
        attribute :username, type: String
        attribute :first_name, type: String
        attribute :password, type: String
        attribute :password_confirmation, type: String

        validates :username, presence: true    # simple validation as an example
                                               # in this case validation really done
                                               # in activerecord User model
      end

      uses_routine CreateUser,
                   translations: { inputs: {scope: :register} }

    protected

      def authorized?
        caller.is_anonymous?
      end

      def handle
        run(CreateUser, first_name:            register_params.first_name,
                        username:              register_params.username,
                        password:              register_params.password,
                        password_confirmation: register_params.password_confirmation)
      end
    end

In the above handler, if the `username` is blank, the validation in the `paramify` block will catch it and add a fatal error to the handler's result object.  This will cause the `failure` block in `handle_with` to be triggered, and `lev_form_for` will watch for these errors in the @handler_result object and mark offending input fields with a configurable CSS class (default to 'error').  If an error occurs during the run of `CreateUser`, the error will be translated back under a `:register` scope (from the call in `uses_routine`), and the error will also be appropriately traced using `lev_form_for`.

If the handler runs error free, the `success` block will be triggered.

## Writing Models in a Lev-enabled Project

A decision to use Lev means you're interested in following the philosophy of "skinny models, skinny controllers".  To achieve "skinny model" zen, we recommend that models obey the following principles:

1. They should hook into the ORM (i.e., inherit from ActiveRecord::Base)
2. They should establish relationships to other models (e.g. belongs_to, has_many, including dependent: :destroy)
3. They should validate **internal** state
    1. They should **not** validate state in related models
    2. They can run limited validations on associations (e.g. checking the presence of relationship, checking that a foreign key is present, etc)
4. They can perform queries when those queries only use internal model state (i.e. arguments to queries should be in the language of the model state)
5. The can create records when those creations only need values internal to this model and take arguments in the language of the internal model state.
6. They should avoid ActiveRecord lifecycle callbacks (and similarly, Observers) except when the callbacks only work on internal model state.  Such callbacks are only good for entangling what should be simple model code in complex code features.
7. They should avoid doing any cross-model work.

When these guidelines are followed, model classes end up being very small and simple.  This is good because:

1. Small, simple code tends to be more stable code (and since a lot of code depends on the models, stable is a very good thing)
2. The models are easy to mock and use in feature tests (not worrying about some random `before_create` callback added for some other random feature)

## Naming Conventions

As mentioned above, a handler is intended to replace the logic in one controller action.  As such, one convention that works well is to name a handler based on the controller name and the action name, e.g. for the `ProductsController#show` action, we would have a handler named `ProductsShow`.

Routines on the other hand are more or less glorified functions that work with multiple models to get something done, so we typically start their names with verbs, e.g. `CreateUser`, `SetPassword`, `ConfirmEmail`, etc.

## Differences between Lev and Rails' Concerns

Both Lev and Concerns remove lines of code from models, but the major difference between the two is that with Concerns, the code still lives logically in the models whereas code in Lev is completely outside of and separate from the models.

Lev's routines (and handlers) know about models, but the models don't know anything about nor are they dependent on the code in routines*.  This makes the models simpler and more stable (a Good Thing).

Since a Concern's code is essentially embedded in model code, if that Concern breaks it can potentially break other unrelated features, something that can't happen with routines.

Routines are especially good when some use case needs to query or change multiple models.  With a routine all of the logic for that use case is in one file.  With a concern, that code could be in multiple models and multiple concerns.

(* one small exception is `delegate_to_routine`)

## Why do we need handlers?

Ever had a form you wanted to make that didn't map right onto a model?  Maybe the form needed to deal with two different models and some random text fields.  With a handler, you can pass all of those fields in form_for style, then use active record type validations in the handler to check those inputs (or pass along to the models to have them run their validations).

Routines and handlers also have a built-in error handling mechanism and they run within a single transaction with a controllable isolation level.

## Installation

Add this line to your application's Gemfile:

    gem 'lev'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lev

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
