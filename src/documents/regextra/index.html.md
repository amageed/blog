---
title: Regextra Project
layout: page
tags: ['intro','page']
pageOrder: 2
---

<style>
.success {
    background-color: rgba(65, 242, 77, 0.1);
}
.error {
    background-color: rgba(198, 15, 19, 0.1);
}
</style>

<a href="https://github.com/amageed/regextra"><img style="position: absolute; top: 80px; right: 0; border: 0;" src="https://s3.amazonaws.com/github/ribbons/forkme_right_red_aa0000.png" alt="Fork me on GitHub"></a>

## About

***Regextra*** is an [open source .NET library](https://github.com/amageed/regextra) built to address problems that are handily solved by regular expressions. One component of the library is the `PassphraseRegex` class, which aids in strong passphrase validation. Using a fluent API, a variety of common rules can be applied to produce a pattern that can be used to validate input. The regex produced is generic enough that it can be used on the back-end, or on the front-end via JavaScript (which this page demonstrates!).

A common question I've seen on StackOverflow is how to write code that enforces strong passphrase or password rules. Popular responses tend to tackle the problem by using a regex with look-aheads. I've seen this so much that I decided to have fun writing a solution that allowed people to produce regex patterns that would enforce such rules.

## Wiki

Refer to the [wiki](https://github.com/amageed/Regextra/wiki) for more details on the API. The rest of this page demonstrates some examples of generated patterns that can be tested via the input form fields.

## Examples

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


## Try It!

Below are some validation goals, followed by the code used to produce the pattern. You can test the pattern out with your own input and the textbox's color will change based on the validity. *All patterns reject leading and trailing whitespace.*

**Goal:** accept input that contains any of the specified characters (**a, b, c, 1, 2, 3**).

```cs
var result = PassphraseRegex.That.IncludesAnyCharacters("abc123")
                                 .ToRegex();

var pattern = result.Pattern;
```

<div class="well">
    <p>**Pattern:** `^(?=.*[abc123])(?!^\s|.*\s$).+$`</p>
    <ul>
      <li>*Valid:* **a**, **1**, **f3**</li>
      <li>*Invalid:* **x**, **z6**, **9**</li>
    </ul>
    <form class="form-group">
        <input type="text" class="form-control" placeholder="Try it..." pattern="^(?=.*[abc123])(?!^\s|.*\s$).+$">
        <p></p>
    </form>
</div>

<hr />

**Goal:** reject input that contains any of the specified characters (**a, b, c, 1, 2, 3**).

```cs
var result = PassphraseRegex.That.ExcludesCharacters("abc123")
                                 .ToRegex();

var pattern = result.Pattern;
```

<div class="well">
    <p>**Pattern:** `^(?!.*[abc123])(?!^\s|.*\s$).+$`</p>
    <ul>
      <li>*Valid:* **x**, **z6**, **9**</li>
      <li>*Invalid:* **a**, **f3**, **2**</li>
    </ul>
    <form class="form-group">
        <input type="text" class="form-control" placeholder="Try it..." pattern="^(?!.*[abc123])(?!^\s|.*\s$).+$"><p></p>
        <p></p>
    </form>
</div>

<hr />

**Goal:** accept input of length 2-6 that contains any of the characters in the range `a-z`.

```cs
var result = PassphraseRegex.With.MinLength(2)
                                 .MaxLength(6)
                                 .IncludesRange('a', 'z')
                                 .ToRegex();

var pattern = result.Pattern;
```

<div class="well">
    <p>**Pattern:** `^(?=.*[a-z])(?!^\s|.*\s$).{2,6}$`</p>
    <ul>
      <li>*Valid:* **ab**, **abc123**, **xyz**</li>
      <li>*Invalid:* **a** (too short), **AB** (case sensitive), **12**, **!@#**, **abcdefg** (too long)</li>
    </ul>
    <form class="form-group">
        <input type="text" class="form-control" placeholder="Try it..." pattern="^(?=.*[a-z])(?!^\s|.*\s$).{2,6}$">
        <p></p>
    </form>
</div>

<hr />

**Goal:** accept input that contains at least 2 occurrences of characters in the `0-9` range and excludes the characters `!`, `@`, `#`, and characters in the `a-z` range. The minimum length is set to 3 based on the number of rules specified, which are the Include/Exclude methods (`WithMinimumOccurrenceOf` isn't counted as a rule since it's a constraint applied to the `IncludesRange` rule).

```cs
    var result = PassphraseRegex.Which.ExcludesRange('a', 'z')
                                      .ExcludesCharacters("!@#")
                                      .IncludesRange(0, 9)
                                      .WithMinimumOccurrenceOf(2)
                                      .ToRegex();

    var pattern = result.Pattern;
```

<div class="well">
    <p>**Pattern:** `^(?!.*[a-z])(?!.*[!@#])(?=.*[0-9].*[0-9])(?!^\s|.*\s$).{3,}$`</p>
    <ul>
      <li>*Valid:* **123**, **8 % $9-4**, **A4 B5** (case sensitive)</li>
      <li>*Invalid:* **0** (too short), **ABC0** (minimum digit occurrence not met), **a1b2**, **123#**</li>
    </ul>
    <form class="form-group">
        <input type="text" class="form-control" placeholder="Try it..." pattern="^(?!.*[a-z])(?!.*[!@#])(?=.*[0-9].*[0-9])(?!^\s|.*\s$).{3,}$">
        <p></p>
    </form>
</div>

<hr />

**Goal:** accept input that contains characters in the `a-z` and `0-9` ranges, with a maximum length of 8 characters, and a maximum of 3 consecutive identical characters. The minimum length is set to 2 based on the number of rules specified, which are the two `Include` methods (the `Max*` methods below aren't counted as rules).</p>

```cs
var result = PassphraseRegex.With.MaxLength(8)
                                 .IncludesRange('a', 'z')
                                 .IncludesRange('0', '9')
                                 .MaxConsecutiveIdenticalCharacterOf(3)
                                 .ToRegex();

var pattern = result.Pattern;
```

<div class="well">
    <p>**Pattern:** `^(?=.*[a-z])(?=.*[0-9])(?!.*?(.)\1{3})(?!^\s|.*\s$).{2,8}$`</p>
    <ul>
      <li>*Valid:* **a1**, **abc123**, **aaa1a** (4 'a' characters total, but not more than 3 of them are consecutive)</li>
      <li>*Invalid:* **abcd12345** (too long), **aaaa1** (exceeds max of 3 consecutive identical character constraint), **abc** (doesn't include any `0-9` characters)</li>
    </ul>
    <form class="form-group">
        <input type="text" class="form-control" placeholder="Try it..." pattern="^(?=.*[a-z])(?=.*[0-9])(?!.*?(.)\1{3})(?!^\s|.*\s$).{2,8}$">
        <p></p>
    </form>
</div>

<hr />

**Goal:** accept input that doesn't contain "foo" anywhere in the text (regardless of case).</p>

```cs
var result = PassphraseRegex.That.ExcludesText("foo")
                                 .Options(RegexOptions.IgnoreCase)
                                 .ToRegex();

var pattern = result.Pattern;
```

<div class="well">
    <p>**Pattern:** `^(?!.*foo)(?!^\s|.*\s$).+$`</p>
    <ul>
      <li>*Valid:* **a1**, **abc123**, **fizz**</li>
      <li>*Invalid:* **foo** (lowercase), **FOO** (uppercase), **abcFoOxyz** (mixed case)</li>
    </ul>
    <form class="form-group">
        <input type="text" class="form-control" placeholder="Try it..." pattern="^(?!.*foo)(?!^\s|.*\s$).+$" pattern-flags="i">
        <p></p>
    </form>
</div>

<script type="text/javascript">
    setTimeout(function() {
        $('form').submit(function(event) {
            event.preventDefault();
        });
        $('form > input').keyup(function() {
            var el = $(this);
            var re = new RegExp(el.attr('pattern'), el.attr('pattern-flags'));
            var isValid = re.test(el.val());
            el.removeClass('error success')
              .addClass(isValid ? 'success' : 'error')
              .parent()
              .removeClass('has-error has-success')
              .addClass(isValid ? 'has-success' : 'has-error');
            el.next().text('Characters: ' + el.val().length);
        });
    }, 1500);
</script>
