---
date: 2013-06-24 04:55:52+00:00
layout: post
url: /posts/sharpkit-evaluation
title: Evaluating SharpKit - a C# to JavaScript converter
tags: ['post','.net','web']
---

Recently the [SharpKit C# to JavaScript converter](http://sharpkit.net/) was mentioned at work and I decided to evaluate it since a few coworkers thought it was interesting. What follows is my impression after using it briefly over the weekend.

This type of tool isn't new; before this I was familiar with [Script#](https://github.com/nikhilk/scriptsharp). That said, SharpKit offers a [comparison to other tools](http://sharpkit.net/Compare.aspx). As you can imagine, being a C# to JavaScript converter, you have all the benefits of writing C# code in Visual Studio, which is a fantastic IDE. Add your favorite third-party productivity tool, such as CodeRush or Resharper, and it's even sweeter.

[According to SharpKit](http://sharpkit.net/About.aspx), they aim to address the challenge of JavaScript productivity:

> JavaScript code turned out to be very hard to maintain, mainly due to the fact that JavaScript’s interpreted nature does not allow IDEs such as Visual Studio to provide high productivity. For instance, Many C# features, such as syntax verification, code completion and refactoring, are simply not available while coding in JavaScript. On top of that, different JavaScript API implementations across web browsers made it even harder to evaluate code correctness during development.

The aim of this post is to share the pros and cons of SharpKit as I see them. I will not be sharing much code or discussing the usage of SharpKit itself. To get a better idea of what SharpKit development is like, I recommend watching their [videos](http://sharpkit.net/Videos.aspx).

I think it's important to state my background and the perspective with which I wrote this evaluation so anyone reading it understands some of my reasoning. I am comfortable with web development, and it shows in my evaluation. I enjoy working directly with JavaScript and the myriad of libraries and tools that come with front-end development. Moreover, I was considering some MV* frameworks for an upcoming project, namely [Backbone](http://backbonejs.org/) and [Angular](http://angularjs.org/), so some of my comments mention them. That said, SharpKit is probably somebody's baby and I respect that they offer a solution to address a particular group of developers. I just don't count myself amongst them, and that's OK.


### Pros

  * Good for C# devs who aren't too familiar or comfortable with JavaScript
  * Compile-time checking (everything is typed - could be a con, see below)
  * Visual Studio Intellisense, third-party plugins, and debugging will all work with the C# code
  * Support for LINQ / Reflection / Generics (comes at a cost though, see cons below)
  * Support for most common libraries, like jQuery, jQueryUI
  * Allows you to create header files to support libraries they don't support, so it's extensible

### Cons (and some general observations)

  * LINQ support comes at a cost. From the [FAQ](http://sharpkit.net/Faq.aspx):

> Advanced support for features such as reflection, LINQ and generics require a small include of the SharpKit JavaScript Kernel (about 60K compressed).

I'm not sure if they mean minified + gzipped by "compressed" or just minified. I minified + gzipped it and it came down to 25K, so it's not clear where that 60K comes from. While it's nice to have, it might not be needed if you're targeting modern browsers that support the common map/foreach functionality natively. For other LINQ type scenarios I would consider [Lo-Dash](http://lodash.com/), which has a smaller footprint (which can be enhanced by creating custom builds with your desired functionality). Alternately, there's [Underscore.js](http://underscorejs.org/) and it weighs in at 14kb minified (4kb gzipped). If there's a real need for a faithful mirror of .NET LINQ, the [LinqJS project](http://linqjs.codeplex.com/) weighs in at 6kb gzipped.


  * Compile-time checking introduces additional casting to satisfy the static nature of C#. Example: after grabbing an element by ID, I need to cast it to the HTML element type (an input field, in this case) to access it's relevant properties...

  ```cs
      var input = document.getElementById("input")
                          .As<SharpKit.Html.HtmlInputElement>();
      input.value = "MyValue";
  ```

If the input element changes to a `select` or `textarea`, I now have to change this code to cast it appropriately, although they both might be accessed by the same `value` property. In [Angular](http://angularjs.org/) this is also a non-issue since the desired property would be bound to the model for us to access directly.

  * I have to rely on a third party to update libraries (e.g., adopting a new jQuery/jQuery-UI/etc. release) or offer a particular library to begin with (Angular, Backbone).
    * Lacks support for Angular and Backbone. I suspect Angular support won't make it anytime soon, if at all, due to how different of a framework it is and how the dependency injection is determined. If it were supported, the amount of nested callbacks and delegates would look nothing like today's JavaScript that's contained in one spot and easier to read.
    * I can't use the JavaScript components of the Bootstrap CSS framework (or Zurb Foundation) since no SharpKit library exists for them.


  * To work around the lack of support for any library, there are 2 solutions:
    1. Write our own SharpKit header files for the libraries. This means reading the JavaScript source code and determining which of the classes and members are required, creating an empty implementation, then decorating them with a `JsTypeAttribute` in the proper mode, and preventing the classes from being exported. This might be a pro, since I can support libraries, but it's extra work whenever I need something.
    2. A hybrid approach using SharpKit + JavaScript. For example, I'd write JavaScript directly, leveraging Bootstrap JavaScript functionality normally (since there's no SharpKit equivalent), then bring in any SharpKit generated JavaScript as modules (i.e., using RequireJS or CommonJS). So I'm back to writing JavaScript anyway and now I'm maintaining an awkward hybrid approach.


  * Devs that are comfortable with JavaScript are penalized and can't leverage their knowledge or much of the power of dynamic languages since they would have to play by the static world's rules (example below).
    * Lose out on the dynamic nature of JavaScript (depending on who you are, that might be a pro). To me this is a loss since a very common JavaScript pattern is to access an object's property via key lookup using strings and usually a concatenated string, making it somewhat comparable to generics in C#.

      **JavaScript:** `console.log(person["Name"]);`

      **SharpKit (w/reflection):**

      ```cs
      foreach (var prop in person.GetType().GetProperties())
      {
          console.log(prop.GetValue(person, null));
      }
      ```

And that will likely generate some interesting looking code and require that 60kb library. I couldn't get this to compile, although they seem to support it. An `ExpandoObject` might do the trick, but that didn't compile for me either. I'm probably missing some setting to access .NET classes.

  * Introduces dev / build workflow challenges. I can't edit a .cs file in Visual Studio while debugging to update the generated JavaScript. We'd need to stop debugging, edit, start debugging / launch the site. That's a step back in productivity. With a JavaScript approach (including CoffeeScript and TypeScript) tools exist to compile changes on the fly, so the workflow is much nicer: edit JS/CS/TS file, a tool watches for changes and compiles them on the fly, a tool also reloads your browser automatically. There's no stop/edit/start since VS isn't in the way; it's just edit/save and the tools take care of the rest.
  * No support for Jasmine or Angular's additions (meaning I would have to test in JavaScript, which was the original plan anyway). SharpKit supports QUnit.

### Other issues

This library should work in Visual Studio 2012, and forums online support that it's just a library to be reference. However, I installed it and the project template only showed up for VS 2010, not VS 2012. I had to ignore the project template and manually import the SharpKit reference since there was no MVC template. Given an existing project, you would want to import the reference by adding it to the .csproj file. I got it to work with VS 2010.

In VS 2012 I manually imported the references. All looked well, but upon compiling and launching the site, the JavaScript file wasn't generated. The same exact setup worked in VS 2010 though. Might be a fluke... uninstalled/reinstalled without a difference in the end result though.

### Closing thoughts

I can see the allure of a tool like SharpKit for devs that would prefer this type of environment who want to be productive with C# and aren't concerned with a couple of things, such as client-side script size / performance, and the stop and go workflow impediment since that's how they typically work with C# / ASP.NET MVC anyway. Given the cons mentioned, I feel it's more suited for projects relying on the supported libraries, and by people that might not have a need to use the libraries I'm interested in - people that aren't accustomed to front-end dev. It's also additional work to produce and update custom header files.

I would rather embrace a real front-end workflow that keeps me in sync with the front-end community today, and embrace the dynamic nature of JavaScript. CoffeeScript and TypeScript are transpilers that still retain dynamic support and don't take that away. SharpKit is more of a library that abstracts that nature away to provide a wrapper with its own classes and work within C#'s static nature.

This reminds me of Web Forms all over again. What I enjoy about ASP.NET MVC is that it allows me to get closer to the metal, avoid abstractions, and enhance my front-end skills. That would all go away by adopting SharpKit's approach and feels like a step backwards. It would also single-handedly eliminate the entire front-end stack I have in mind and I don't think a tool should wield so much power over technical decisions and dictate what I can and cannot use.

I only spent a weekend evaluating this library, so I'm sure I missed some features or might have made a mistaken assumption along the way. Overall, I think I got the gist of working with it and it's not for me. I'm comfortable developing and debugging JavaScript. I mainly use Sublime Text as my IDE for front-end development, and I can setup a JS linter if I'm concerned with catching JS gotchas. If I wanted to work with a more static aware flavor of JavaScript, I would consider [TypeScript](http://www.typescriptlang.org/).
