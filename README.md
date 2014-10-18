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

Two methods are provided for adding errors: `fatal_error` and `nonfatal_error`.
Both take a hash of args used to create an Error and the former stops routine
execution.  In its current implementation, `nonfatal_error` may still cause
a routine higher up in the execution hierarchy to halt running.

    class MyRoutine
      lev_routine

    protected
      def exec(foo, options={})  # whatever arguments you want here
        fatal_error(code: :some_code_symbol) if foo.nil?
        outputs[:bar] = foo * 2
      end
    end
  
  
A routine will automatically get both class- and instance-level `call`
methods that take the same arguments as the `exec` method.  The class-level
call method simply instantiates a new instance of the routine and calls 
the instance-level call method (side note here is that this means that 
routines aren't typically instantiated with state).

When called, a routine returns a `Result` object, which is just a simple wrapper
of the outputs and errors objects. 
  
    result = MyRoutine.call(42)
    puts result.outputs[:bar]    # => 84

### Raising Errors in Routines

... to be written ..

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

### Specifying Transaction Isolations

A routine is automatically run within a transaction.  The isolation level of the routine can be set by passing a `:transaction` option to the `lev_routine` call (or to the `lev_handler` call, if appropriate).  The value must be one of the following:
  
* `:no_transaction`
* `:read_uncommitted`
* `:read_committed`
* `:repeatable_read`
* `:serializable`
  
Note that by setting an isolation level, you are stating the minimum isolation level at which a routine must be run.  When routines are nested inside each other, the highest-specified isolation level from any one of them is used in the one transaction in which all of a routines' subroutines run.



  
  
  A routine is 
  
  e.g.
  
    class MyRoutine
      lev_routine transaction: :no_transaction
  

### delegate_to_routine

TBD

### Other Routine Methods
  
Routine class have access to a few other methods:

1. a `runner` accessor which points to the routine which called it. If
   runner is nil that means that no other routine called it (some other 
   code did)
2. a `topmost_runner` accessor which points to the highest routine in the calling
   hierarchy (that routine whose 'runner' is nil)


## Handlers

(all Handlers are Routines, so most everything for Routines applies here)

Handlers are specialized routines that take user input (e.g. form data) and then take an action based on that input.  

Handlers...

1. Help you verify that the calling user is authorized to run the handler
2. Provide ways to validate incoming parameters in a very ActiveModel-like way (even when the parameters are not associated with a model)
3. Integrate well with basic routines
4. Map one-to-one with controller actions; by keeping the logic in each controller action encapsulated in a Handler, the code becomes independently-testable and also prevents the controller from being "fat" with 7 different actions all containing disparate logic touching different models.

In a Lev-oriented Rails app, controllers are just responsible for connecting routes to Handlers.  In fact, controller methods just end up being calls to ```handle_with(MyHandler)```, ```handle_with``` being a helper method provided by Lev.  

Lev also provides a ```lev_form_for``` form builder to replace ```form_for```.  This builder integrates well with the error reporting infrastructure in routines and handlers, and in general is a nice way to get away from forms that are very single-model-centric.

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
