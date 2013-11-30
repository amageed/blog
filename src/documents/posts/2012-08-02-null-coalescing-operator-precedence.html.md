---
date: 2012-08-02 11:50:16+00:00
layout: post
url: /posts/null-coalescing-operator-precedence
title: The C# null coalescing operator and when 2 + 3 = 2
tags: ['post','.net','c#']
---

Recently I was working with some nullable objects that I needed to add together. This led to some incorrect results when I wrote the code to sum them up due to the use of the [null coalescing operator](http://msdn.microsoft.com/en-us/library/ms173224.aspx).

The good news is that I wrote the code in a particular way, on purpose, to see what the compiler would do and my intuition proved to be correct. On top of that, I had some unit tests in place, so I was confident that a wrong result would get caught immediately. While I don't think this is an earth-shattering finding, a quick search shows that the issue has tripped up a few people.

Quick, what's 2 + 3? Would you expect the answer to be 2? If not, then read on! Here is some code to put this all in perspective.

```cs
int? x = 2;
int? y = 3;

int result = x ?? 0 + y ?? 0;
Console.WriteLine(result);  // 2
```

So why did I end up with a result of two? Clearly 2 + 3 = 5, not 2! The answer is that the precedence rules for the _?? operator_ played a role in returning the odd result.

After reviewing the [C# operators precedence rules](http://msdn.microsoft.com/en-us/library/6a71f45d.aspx), I found that the _?? operator_ has a very low precedence. The addition operator has higher precedence than it, which essentially causes the entire expression to be evaluated as follows:

```cs
// parenthesize based on higher precedence of addition
x ?? (0 + y) ?? 0
x ?? (0 + 3) ?? 0  // y is 3

// the left-hand operand, x, isn't null
// so use its value and ignore the right-hand operand
(x ?? 3) ?? 0

x ?? 0  // once again, ignore the right-hand operand
2       // result is x, which is 2
```

Bear in mind that these steps may not be exactly how the C# compiler evaluates the expression, but they're close enough to illustrate how it arrives to the seemingly incorrect result. Eric Lippert's post titled, "[Precedence vs Associativity vs Order](http://blogs.msdn.com/b/ericlippert/archive/2008/05/23/precedence-vs-associativity-vs-order.aspx)," sheds some light on how the compiler evaluates expressions if you're looking for more detail.

As you may have guessed, the solution to return the expected result is to group the operator in parentheses so that the intended precedence is maintained. The following code yields the correct result of five:

```cs
int? x = 2;
int? y = 3;

int result = (x ?? 0) + (y ?? 0);
Console.WriteLine(result);  // 5, as intended
```

An alternate approach, applicable with nullable types, is to use the [`Nullable.GetValueOrDefault` method](http://msdn.microsoft.com/en-us/library/72cec0e0.aspx). However, it doesn't have the brevity of the _?? operator_.

```cs
int result = x.GetValueOrDefault() + y.GetValueOrDefault();
```

Most people have an idea of general precedence rules, but as software developers we run into more operators with different levels of precedence. For clarity, and when you're in doubt, group your expressions in parentheses.
