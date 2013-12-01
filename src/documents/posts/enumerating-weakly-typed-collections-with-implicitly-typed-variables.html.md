---
date: 2011-11-27 18:28:23+00:00
layout: post
title: Enumerating weakly typed collections with implicitly typed variables
tags: ['post','.net','c#','linq']
---

The advent of C# 3.0 introduced the ability to use implicitly typed local variables via the [`var` keyword](http://msdn.microsoft.com/en-us/library/bb383973.aspx). Usage of `var` has flourished since then, and while some people use it judiciously, others make liberal use of it. Ultimately, most people are bound to run into a scenario where it surprisingly ceases to behave properly. Suddenly using `var` in a foreach loop causes IntelliSense to stop working properly, and an error is generated upon compiling.

The scenario I'm referring to is enumerating over weakly typed collections. This is common when working with COM, Microsoft Office interop, an `ArrayList`, and any collection that returns a non-generic `IEnumerable` (i.e., an `IEnumerable<object>`).

I'll use this simple `Car` class to demonstrate in the upcoming examples:

```cs
public class Car
{
    public string Make { get; set; }
    public string Model { get; set; }
    public bool IsHybrid { get; set; }

    public Car(string make, string model, bool isHybrid)
    {
        Make = make;
        Model = model;
        IsHybrid = isHybrid;
    }
}
```

Now, consider the following example:

```cs
var cars = new ArrayList()
{
    new Car("BMW", "335i", false),
    new Car("Infiniti", "G37", false),
    new Car("Toyota", "Prius", true)
};

foreach (var c in cars)
{
    Console.WriteLine(c.Make);
}
```

As I write the line inside the foreach loop, I immediately notice something fishy. When I type `"c."` the IntelliSense suggestions pop up, but the properties on the `Car` class are missing! I expect to see `Make`, `Model`, and `IsHybrid` in the popup, but they are visibly absent. What gives?

<p class="text-center">
    ![Screenshot of IntelliSense and missing properties](/images/CarNoIntelliSense.png "Car object missing properties")
    <p>Screenshot of IntelliSense and missing properties</p>
</p>

Since `ArrayList` returns an `IEnumerable<object>` the usage of `var` results in the variable `c` being an `object` type. With this in mind, it makes sense that the only IntelliSense items available are the ones that are defined on all objects.

Ignoring this early warning that something is amiss, attempting to compile the code would generate this error:


> 'object' does not contain a definition for 'Make' and no extension method 'Make' accepting a first argument of type 'object' could be found (are you missing a using directive or an assembly reference?)





### Workaround #1: Be explicit


The most straightforward solution is to use an explicitly typed local variable. In this case, we would use `Car` instead of `var`. The updated code will make IntelliSense work as expected, and compiles correctly.

```cs
foreach (Car c in cars)
{
    Console.WriteLine(c.Make);
}
```

So what's the difference and why does this approach work? Allow me to refer to the C# language specification in order to "PhD things up," as one of my co-workers fondly enjoys accusing me of doing occasionally! Essentially, it works because an implicit cast is occurring within the foreach. Section 8.8.4 of the spec (version 4.0) details how the `foreach` statement determines the type when `var` is specified. A bunch of steps take place to determine the type, and they are beyond the scope of this post, however the relevant part of the spec that this falls under occurs when the compiler checks for an enumerable interface. In particular, the spec states:



> Otherwise, if there is an implicit conversion from X to the System.Collections.IEnumerable interface, then the collection type is this interface, the enumerator type is the interface System.Collections.IEnumerator, and the element type is object.




The spec also shows the individual components of the `foreach` statement and its expansion, which clarifies how the casting occurs.



### Workaround #2: LINQ to the rescue!


With LINQ we can use the [Enumerable.Cast method](http://msdn.microsoft.com/en-us/library/bb341406.aspx) (or [Enumerable.OfType](http://msdn.microsoft.com/en-us/library/bb360913.aspx)) to cast all the elements of the `IEnumerable` to a given type. In our case, we will specify a `Car` type and the result will be a strongly-typed `IEnumerable<Car>`.

```cs
foreach (var c in cars.Cast<Car>())
{
    Console.WriteLine(c.Make);
}
```

The equivalent query syntax is:
```cs
var query = from Car c in cars
            select c;

foreach (var c in query)
{
    Console.WriteLine(c.Make);
}
```

Notice that the range variable `c` is explicitly typed in the [from clause](http://msdn.microsoft.com/en-us/library/bb383978.aspx) and omitting the type by writing `from c in cars` would have generated this compile-time error:



> Could not find an implementation of the query pattern for source type 'System.Collections.ArrayList'.  'Select' not found.  Consider explicitly specifying the type of the range variable 'c'.



Normally, when working with data sources which implement IEnumerable<T>, we can omit the type since the compiler infers it.

While the above approaches illustrate the point, the first workaround is the preferred way to deal with this issue unless we plan to do more with the LINQ query. The `Enumerable` methods are beneficial when constructing a larger LINQ query, allowing us to chain multiple extension methods together. Understanding how [extension methods](http://msdn.microsoft.com/en-us/library/bb383977.aspx) work is vital to appreciate how this all fits together.

In brief, `Enumerable.Cast` extends the `IEnumerable` type, which is why it is available for use on the `cars ArrayList`. The result is a strongly-typed `IEnumerable<Car>`. Since a large majority of extension methods extend `IEnumerable<T>`, we can begin to use them after using the `Cast` or `OfType` extension methods. Even `Enumerable.Select`, the most basic of extension methods, isn't available until one of the aforementioned extension methods is used.

As an example of method chaining, the following query can be used to group hybrid and non-hybrid cars together:

```cs
var hybridGroups = cars.Cast<Car>().GroupBy(c => c.IsHybrid);

foreach (var group in hybridGroups)
{
    Console.WriteLine("{0} Cars: {1}",
        group.Key ? "Hybrid" : "Non-Hybrid",
        group.Count());

    foreach (var c in group)
    {
        Console.WriteLine("- {0} {1}", c.Make, c.Model);
    }
}
```
