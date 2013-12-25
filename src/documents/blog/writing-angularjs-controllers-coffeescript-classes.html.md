---
date: 2013-09-08 06:23:27+00:00
layout: post
title: Writing AngularJS controllers with CoffeeScript classes
tags: ['post','angular','coffeescript','javascript']
---

When I started using AngularJS one of the obstacles I ran into was using CoffeeScript classes to develop the controllers. Most examples show an inline JavaScript function, which I can easily duplicate with CoffeeScript. However, to make use of a CoffeeScript class, I had to play around with it till I figured it out.

In this post I'll provide a look at converting the simple Todo app on the Angular page to CoffeeScript. I'll cover the process I went through while figuring this out, which includes:

  1. A 1:1 JavaScript to CoffeeScript conversion using functions
  2. Using a CoffeeScript class with all functions defined in the constructor, off of `$scope` (don't do this)
  3. Defining methods on the class instead of on `$scope` and assigning the class to the `$scope` (good)
  4. Using the new Angular 1.1.5+ `controller as` syntax and an example of CoffeeScript using a class and base class (good)

### Original Todo App

To begin with, familiarize yourself with the original Angular Todo app written in JavaScript:

<a class="jsbin-embed" href="http://jsbin.com/eJOVofO/1/embed?html,js,output">JS Bin</a><script src="http://static.jsbin.com/js/embed.js"></script>

### 1:1 Conversion to CoffeeScript

When using CoffeeScript the output is typically generated within an anonymous function to avoid polluting the global namespace (unless you're using the `bare` compilation option). This poses a challenge when converting the example from JavaScript to CoffeeScript. When doing so, you'll likely run into this error: _Argument 'TodoCtrl' is not a function, got undefined_

To address this issue:

  1. Add a module name for the Angular application: `<html ng-app="todoApp">`
  2. Add the controller to the _todoApp_ module in the CoffeeScript file:

```javascript
angular.module("todoApp", [])
  .controller("TodoCtrl", TodoCtrl)
```

The following JS Bin shows the 1:1 conversion result.

<a class="jsbin-embed" href="http://jsbin.com/eJOVofO/2/embed?html,js,output">JS Bin</a><script src="http://static.jsbin.com/js/embed.js"></script>

### Using a CoffeeScript class with Methods on $scope

Great, we now have CoffeeScript code! To use a CoffeeScript class the first thing to figure out is how to use Angular dependency injection (DI). The answer is to pass everything as constructor parameters, as follows:

```javascript
class TodoCtrl
    constructor: ($scope) ->
        $scope.todos = [
            text: "learn angular"
            done: true
        ,
            text: "build an angular app"
            done: false
        ]
```

Once you do that, you run into another error: _Uncaught ReferenceError: $scope is not defined todo.js:23_

It turns out all the methods being defined on `$scope` cause that error since `$scope` isn't defined. You could solve this by moving all the function definitions off of `$scope` into the constructor.

<a class="jsbin-embed" href="http://jsbin.com/eJOVofO/3/embed?js,output">JS Bin</a><script src="http://static.jsbin.com/js/embed.js"></script>

This approach isn't recommended. It's not ideal and isn't making use of the CoffeeScript class. We'll fix that next.

### Improved CoffeeScript Class Without Relying on $scope

To leverage a proper class we need to define the functions on the class instead of on the `$scope`. Here are the changes I've made to the HTML and CoffeeScript files to facilitate this:

  1. Assign `$scope` to the class in the constructor. This is done by using the `@` prefix: `constructor: (@$scope) ->`
  2. For now I've kept the `todos` array hanging off of $scope, which means we would need to refer to it via `@$scope` in all methods. That's why step #1 was done.
  3. Change all `$scope` methods to class methods

As soon as that's done we run into two issues:

  * Issue: archive functionality breaks. To fix it we need to use a fat arrow in the `angular.forEach` to maintain the proper scope or rewrite the loop. The former looks like this:

  ```javascript
      archive: ->
          oldTodos = @todos
          @todos = []
          angular.forEach(oldTodos, (todo) =>
              @todos.push(todo) unless todo.done
          )
  ```

  * Issue: all methods bound to in HTML are hanging off `$scope` so they don't render to the page. The remaining count is missing and the text appears as "remaining of 2". The `addTodo` method is broken too. We need a way to access the controller methods and this is done by assigning the controller to the `$scope` in the constructor and updating the template to access the methods from the controller. Thus, we prefix all methods with `ctrl.`, e.g., `ctrl.remaining()` (same for `archive` and `addTodo`).

  ```javascript
  constructor: (@$scope) ->
    # todos here
    $scope.ctrl = @
  ```

Here's the full JS Bin sample of this approach:

<a class="jsbin-embed" href="http://jsbin.com/eJOVofO/4/embed?html,js,output">JS Bin</a><script src="http://static.jsbin.com/js/embed.js"></script>

### CoffeeScript Class, Base Class, and Controller As Syntax

The _controller as_ syntax was introduced in Angular 1.1.5, and it allows us to achieve the same result as assigning the controller to the scope. Rather than doing so in the CoffeeScript file, we can move it to the markup which makes it much more readable.

In this final example I've made the following changes:

  * Changed Angular library to 1.1.5+
  * Moved `todos` array and `todoText` to the class and update their template references (no more `$scope` reliance, except to log it to the console)
  * Used _Controller as_ syntax and updated template to prefix `ctrl.` as needed
  * Introduced a `BaseCtrl` which the `TodoCtrl` will inherit from to make use of the `toJson` base method
  * Added a `textarea` bound to the base `toJson` method
  * Applied DI via the `$inject` approach to address minification concerns

<a class="jsbin-embed" href="http://jsbin.com/eJOVofO/5/embed?html,js,output">JS Bin</a><script src="http://static.jsbin.com/js/embed.js"></script>

### CoffeeScript and ng-min Incompatibility

Unfortunately if you used to depend on [ng-min](https://github.com/btford/ngmin) to convert the inline function DI approach to bracket notation it will no longer work with CoffeeScript classes. To address this you should use the `$inject` property instead, which I demonstrated in the final example above.
