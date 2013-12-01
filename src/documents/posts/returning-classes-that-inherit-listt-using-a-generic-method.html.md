---
date: 2012-03-05 14:35:10+00:00
layout: post
title: Returning classes that inherit List<T> using a generic method
tags: ['post','.net','c#']
---

Recently a past coworker came across a problem and issued a code challenge to some of her colleagues to help figure it out. This post is my response to that challenge.

### Problem and Challenge

In an effort to enhance the readability of a `List<T>`, especially when nested within another list, the developer decided to implement a new class that inherits from `List<T>`. This looks like:

```cs
public class ProductList : List<Product> { }
```

She wanted to have an extension method that would operate on the `List<T>` but return the actual type that inherited from it (`ProductList`, in this example).

To illustrate, consider an extension method that simply skips the first item in a list and returns the remaining items (exciting, I know). This sample reflects the approach taken:

```cs
public static class Extensions
{
    public static List<T> SkipFirst<T>(this List<T> input)
    {
        List<T> result = input.Skip(1).ToList();
        return result;
    }
}
```

The extension method was used in the following manner:

```cs
ProductList result = (ProductList)list.SkipFirst();
```

This caused an `InvalidCastException` to be thrown:

> Unable to cast object of type 'System.Collections.Generic.List`1[CollectionInheritance.Product]' to type 'CollectionInheritance.ProductList'


At this point she could've fallen back on using `List<T>` but she worked around it using AutoMapper instead. The problem with that approach is that the original intention to provide an elegant solution to be used with other classes following the same inheritance setup was somewhat lost. It now required two steps: (1) calling `SkipFirst`, and (2) mapping from `List<T>` to `TList`.

Dissatisfied, she issued the code challenge seeking an extension method that would work with classes which inherit from `List<T>` without using AutoMapper.

<p class="text-center">
    ![Generics and Inheritance? Challenge Accepted!](/images/ChallengeAcceptedGenericsInheritance.jpg)
</p>

### Understanding why casting fails

Before I get to my solution I wanted to shed some light on why casting doesn't work. As seen earlier, an explicit cast threw an `InvalidCastException`. Similarly, usage of the [`as` operator](http://msdn.microsoft.com/en-us/library/cscsdfbt.aspx) is incorrect and would return a _null_ result.

The reason both approaches fail is because `ProductList` and `List` are different types! Yes, they represent the same thing to us on the outside, but they aren't the same.

Jeffrey Richter touches upon this very topic in his excellent [CLR via C#](http://www.amazon.com/gp/product/0735627045/ref=as_li_tf_tl?ie=UTF8&tag=softwaninjan-20&linkCode=as2&camp=1789&creative=9325&creativeASIN=0735627045) book (p. 287, 3rd ed.):

> "... you should never define a new class explicitly for the purpose of making your source code easier to read. The reason is because you lose type identity and equivalence..."

He continues with an example to demonstrate, similar to what follows, which evaluates to _false_:
```cs
bool sameType = typeof(List<Product>) == typeof(ProductList); // false
```

With that in mind, it's clear why casting won't work. Likewise, the `as` operator returns a null value since, by definition, if the conversion fails it will return null instead of throwing an exception.

Another important point (also raised in the book) is that this approach prevents `List<T>` from being passed to a method that expects the new class which inherits from `List<T>` as a parameter. However, going in the opposite direction is allowed. In other words, passing a `List<Product>` to a method that accepts a `ProductList` would fail, but passing a `ProductList` to a method expecting `List<Product>` is valid since `ProductList` inherits from `List<Product>`.

### Solution

To meet the challenge I wrote the following extension method:

```cs
public static TCollection SkipFirst<T, TCollection>
    (this ICollection<T> input)
        where TCollection : ICollection<T>, new()
{
    var processedItems = input.Skip(1);

    var result = new TCollection();
    foreach (T item in processedItems)
    {
        result.Add(item);
    }

    return result;
}
```

Usage:

```cs
ProductList result = list.SkipFirst<Product, ProductList>();
```

There you go! Nice and succinct. No casting, and no need for the extra line of code to use AutoMapper. The key to this puzzle was to return `TCollection`, instead of a `List<T>`. Furthermore, adding the generic constraints ensures that `TCollection` implements `ICollection<T>` and has a public parameterless constructor in order to new up an instance of the class.

Note that `List<T>` and `IList<T>` could've been used in the extension method.

### Implementing custom collections and public APIs

For simplicity's sake it's not uncommon to see a subclass of `List<T>`. Perhaps this is acceptable for internal usage, however it isn't recommended when exposed in a _public API_. This issue has been [brought up](http://stackoverflow.com/q/5376203/59111) [numerous](http://stackoverflow.com/q/3748931/59111) [times](http://stackoverflow.com/q/21715/59111). If a custom collection needs to have special behavior then it's possible to change the collection's implementation if inheriting from classes meant to be extended.

To paraphrase [Krzysztof Cwalina](blogs.msdn.com/b/kcwalina/archive/2005/09/26/474010.aspx), co-author of the .NET [Framework Design Guidelines](http://www.amazon.com/gp/product/0321545613/ref=as_li_tf_tl?ie=UTF8&tag=softwaninjan-20&linkCode=as2&camp=1789&creative=9325&creativeASIN=0321545613), `List<T>` wasn't meant to be extended, unlike `Collection<T>` which lets you override its members and supports awareness of item modification. Also, `List<T>` returns a rich set of members that typically aren't appropriate for all scenarios.

This guideline is also covered by a Code Analysis warning, [CA1002: Do not expose generic lists](http://msdn.microsoft.com/en-us/library/ms182142.aspx). David Kean, a member of the Code Analysis team, expanded on this warning with supporting code examples in the post titled [FAQ: Why does DoNotExposeGenericLists recommend that I expose Collection<T> instead of List<T>?](http://blogs.msdn.com/b/codeanalysis/archive/2006/04/27/faq-why-does-donotexposegenericlists-recommend-that-i-expose-collection-lt-t-gt-instead-of-list-lt-t-gt-david-kean.aspx)
