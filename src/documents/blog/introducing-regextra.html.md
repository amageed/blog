---
date: 2014-03-10 22:25:00+00:00
layout: post
title: Regextra: helping you reduce your (problems){2}
tags: ['post','regextra','regex','oss']
---

I'm a fan of regular expressions and tend to be the go-to guy on teams when it comes to (concoct|conjur)ing patterns. I've also [answered a good amount of regex related questions](http://stackoverflow.com/search?tab=votes&q=regex%20user%3a59111) on StackOverflow.

One of the questions that frequently gets asked is how to construct a pattern that enforces passphrase/password validation with a number of criteria. These are the rules you typically see when signing up on the majority of websites: *your password must include at least 1 uppercase letter, 1 lowercase letter, 1 digit, 3 oz. Unicorn tears, and 16 scruples of Fluxweed...* you get the idea.

Other questions revealed a host of handy techniques that I wanted to capture, such as [splitting strings and including the delimiters](http://stackoverflow.com/a/2485044/59111), trimming whitespace, and formatting camel case values.

## Enter Regextra

A little over a year ago I started working on a library to address these problems and capture useful solutions. I've been working on it on and off and recently devoted much more time to it to add some finishing touches before releasing it on NuGet. Without further ado, I'm finally happy to reveal it!

[Regextra](https://github.com/amageed/Regextra) (pronounced "Rej-extra") is an open-source .NET library written in C#. It's well tested, with over 200 unit tests.

Currently, the library includes the following features:

  - Passphrase Regex Builder
  - Named Template Formatting
  - Useful regex/string methods

Over time I hope to add other useful features, and would love to hear any community feedback on what the library accomplishes today. The goal of this project was to address common scenarios, however that's not to be confused with amassing all sorts of patterns. This is more of a helpful utility, not an encyclopedia of patterns.

## Getting Started

  - Check out the [wiki](https://github.com/amageed/Regextra/wiki)
  - Visit the project's [demo site](http://softwareninjaneer.com/regextra) for a chance to try out some client-side validation (using the patterns produced by the `PassphraseRegex` builder)
  - The extensive [test suite](https://github.com/amageed/Regextra/tree/master/src/Tests) is worth a glance

Regextra is available via [NuGet](https://www.nuget.org/packages/Regextra/):

```
PM> Install-Package Regextra
```

## Passphrase Regex Builder

A common question I've seen on StackOverflow is how to write code that enforces strong passphrase or password rules. Popular responses tend to tackle the problem by using a regex with look-aheads. I've seen this so much that I decided to have fun writing a solution that allowed people to produce regex patterns that would enforce such rules.

### Example usage

The following code generates a pattern to enforce a password of 8-25 characters that requires at least two lowercase letters in the range of `a-z` and numbers excluding those in the range of `0-4` (i.e., numbers in the `5-9` range are acceptable).

```cs
var builder = PassphraseRegex.With.MinLength(8)
                                  .MaxLength(25)
                                  .IncludesRange('a', 'z')
                                  .WithMinimumOccurrenceOf(2)
                                  .ExcludesRange(0, 4);

PassphraseRegexResult result = builder.ToRegex();

if (result.IsValid)
{
    if (result.Regex.IsMatch(input))
    {
        // passphrase meets requirements
    }
    else
    {
        // passphrase is no good
    }
}
else
{
    // check the regex parse exception message for the generated pattern
    Console.WriteLine(result.Error);
}
```

Refer to the [PassphraseRegex wiki](https://github.com/amageed/Regextra/wiki/PassphraseRegex:-building-passphrase-validation-patterns) for further details and examples.

## Template Formatting

Template formatting allows you to perform named formatting on a string template using an object's matching properties. It's available via the static `Template.Format` method and the string extension method, `FormatTemplate`. The formatter features:

  - Nested properties formatting
  - Dictionary formatting
  - Standard/Custom string formatting
  - Escaping of properties
  - Detailed exception messages to pinpoint missing properties
  - Great performance (in part thanks to [FastMember](http://code.google.com/p/fast-member/))

### Example usage

```cs
var order = new
{
    Description = "Widget",
    OrderDate = DateTime.Now,
    Details = new
    {
        UnitPrice = 1500
    }
};

string template = "We just shipped your order of '{Description}', placed on {OrderDate:d}. Your {{credit}} card will be billed {Details.UnitPrice:C}.";

string result = Template.Format(template, order);
// or use the extension: template.FormatTemplate(order);
```

The result of the code is:

> We just shipped your order of 'Widget', placed on 2/28/2014. Your {credit} card will be billed $1,500.00.

Refer to the [Template wiki](https://github.com/amageed/Regextra/wiki/Template:-named-formatting) for further details and examples.

## RegexUtility Class

This static class features a couple of helpful methods, such as:

  - **Split Methods**
    - `Split`
    - `SplitRemoveEmptyEntries`
    - `SplitIncludeDelimiters`
    - `SplitMatchWholeWords`
    - `SplitTrimWhitespace`

  - **Formatting Methods**
    - `TrimWhitespace`
    - `FormatCamelCase`

  - **Named Groups Conversion Methods**
    - `MatchesToNamedGroupsDictionaries`
    - `MatchesToNamedGroupsLookup`

### Split and Include Delimiters

```cs
string input = "123xx456yy789";
string[] delimiters = { "xx", "yy" };
var result = RegexUtility.SplitIncludeDelimiters(input, delimiters);
// { "123", "xx", "456", "yy", "789" }
```

### Combining Split Options

```cs
string input = "StackOverflow Stack OverStack";
string[] delimiters = { "Stack" };
var splitOptions = SplitOptions.TrimWhitespace | SplitOptions.RemoveEmptyEntries;
var result = RegexUtility.Split(input, delimiters, splitOptions: splitOptions);
// { "Overflow", "Over" }
```

### Trimming Whitespace

```cs
var result = RegexUtility.TrimWhitespace("   Hello    World   ");
// "Hello World"
```

### FormatCamelCase

Formats PascalCase (upper CamelCase) and (lower) camelCase words to a friendly format separated by the given delimiter (space by default).

It properly handles acronyms too. For example "XML" is properly preserved when given an input of `"PickUpXMLInFiveDays"`. The result is `"Pick Up XML In Five Days"`.

```cs
RegexUtility.FormatCamelCase("PascalCase")        // Pascal Case
RegexUtility.FormatCamelCase("camelCase42", "_")  // camel_Case_42
```

### Matches To Named Groups Dictionaries

Returns an array of `Dictionary<string, string>` of each match with the named groups as the keys, and the group's corresponding value.

```cs
var input = "123-456-7890 hello 098-765-4321";
var pattern = @"(?<AreaCode>\d{3})-(?<First>\d{3})-(?<Last>\d{4})";
var results = RegexUtility.MatchesToNamedGroupsDictionaries(input, pattern);
```

This code returns the following result:

![Named Groups Dictionaries](http://i.imgur.com/hnHpjHL.png)

Refer to the [RegexUtility wiki](https://github.com/amageed/Regextra/wiki/RegexUtility:-miscellaneous-string-manipulation-and-regex-operations) for further details and examples.

## Check it out, Feedback Welcome

Regextra's [source is on GitHub](https://github.com/amageed/Regextra), and you can grab it from [NuGet](https://www.nuget.org/packages/Regextra/).

Please try it out and let me know what you think. Feedback is welcome, so feel free to leave comments or [open issues](https://github.com/amageed/Regextra/issues).