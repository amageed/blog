---
date: 2014-03-28 22:00:00+00:00
layout: post
title: .NET gotcha: number validation and when unicode attacks!
tags: ['post','regex','c#','.net','unicode']
---

Imagine you're working with .NET and have some numeric input with a specific format that you need to validate and convert the number portion to do something interesting with. You decide to tackle this using regular expressions. 

You get to work, quickly constructing a pattern using the `\d` metacharacter to match digits, then use `int.Parse` on the match. Everything checks out, your unit tests pass, and you deploy your app. You're a regex ninja!

Fast forward and you start noticing errors being logged around your regex. Specifically, exceptions are being thrown on the `int.Parse` portion. Surprised, you think, "What?! That's impossible! The regex is solid. It matches numbers, so how could `int.Parse` possibly fail?"

Well, the hint is in this post's title. Consider this snippet:

```cs
string input = "42";
string pattern = @"^\d+$";
Match m = Regex.Match(input, pattern);
if (m.Success) 
{
	int num;
	bool result = int.TryParse(m.Value, out num);
	Console.WriteLine("Matched number: {0} -- Parsed: {1}", input, result);
}
else
{
	Console.WriteLine("Invalid number: {0}", input);
}

// Matched number: 42 -- Parsed: True
```

Simple, right? To get this to fail let's pass in some Arabic numbers:

```cs
string input = "\x0664\x0662"; // Arabic #42: ٤٢

// Matched number: ٤٢ -- Parsed: False
```

Notice that the output indicates that the Arabic numbers were valid. The regex matches but `int.TryParse` fails. In the scenario I described earlier we used `int.Parse`, confident that we would have a valid number, but in this example `int.Parse` will throw a `FormatException`.

The reason is `\d` matches more than just 0-9. According [to MSDN](http://msdn.microsoft.com/en-us/library/20bw873z%28v=vs.110%29.aspx "Character Classes in Regular Expressions") (emphasis mine):

 > `\d` matches any decimal digit. It is equivalent to the `\p{Nd}` regular expression pattern, which includes the standard decimal digits 0-9 as well **as the decimal digits of a number of other character sets**.

If you normally validate numbers using `^\d+$` it clearly isn't enough. There are two ways around this, to limit the valid digits to 0-9:

  1. Use `[0-9]` instead. It is explicit and will not accept unicode decimal digits.
  2. Continue using `\d` and add `RegexOptions.ECMAScript` to use ECMAScript-compliant behavior. This option makes `\d` equivalent to `[0-9]`.

An updated snippet with the ECMAScript option follows:

```cs
string input = "\x0664\x0662";
string pattern = @"^\d+$";
Match m = Regex.Match(input, pattern, RegexOptions.ECMAScript);
// ... same code as before ...

// Invalid number: ٤٢
```

Note, there are similar issues when using `\w` where it isn't limited to ASCII characters. Refer to [ECMAScript Matching Behavior](http://msdn.microsoft.com/en-us/library/yd1hzczs%28v=vs.110%29.aspx#ECMAScript). In addition, the same issue applies to `Char.IsDigit` and `Char.IsLetter`.

To demonstrate:

```cs
string input = "\x0664\x0662";
Console.WriteLine(Char.IsDigit(input[0])); // True
```

Next time you reach for `\d`, keep these issues in mind! Typically someone will opt for `\d` thinking it's shorter while being unaware of these implications.