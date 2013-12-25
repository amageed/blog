---
date: 2011-09-21 05:44:03+00:00
layout: post
title: Regex engine updated to allow timeouts in .NET 4.5
tags: ['post','.net','regex']
---

Many new features were listed as part of [what's new in the .NET Framework 4.5 Developer Preview](http://msdn.microsoft.com/en-us/library/ms171868%28v=vs.110%29.aspx), but the one that caught my eye was this Regex engine update:

> _Ability to limit how long the regular expression engine will attempt to resolve a regular expression before it times out._

Eager to try this feature out I installed the [Visual Studio 11 Developer Preview](http://www.microsoft.com/download/en/details.aspx?displaylang=en&id=27543). For what it's worth, I initially setup the Windows 8 Developer Preview in VirtualBox and played with Visual Studio 11 there, but that's not necessary. I later installed the VS 11 Developer Preview on my machine and it behaved nicely as a side by side install with VS 2010.

At the time of this writing this post refers to the .NET Framework 4.5 Developer Preview. The current MSDN documentation about this new feature can be found [here](http://msdn.microsoft.com/en-us/library/c75he57e%28v=VS.110%29.aspx). Should the implementation change in the RTM version I will try to update this post accordingly.

## Why is this feature helpful?

If you've written a few regular expressions the chances are you've encountered a pattern that caused the regex engine to take a lengthy amount of time to complete. Some might even claim that the engine hangs and they aren't going to wait around to find out if a match is finally returned. Despite the excessive processing time you may have wound up with the correct result. However, the time spent may not be acceptable for your application.

Here are a few scenarios where poor regex performance may occur:

  * Accepting user supplied input to perform a search on data.

  * Accepting user supplied regex patterns to search data.

  * Working with large string inputs.

  * Using patterns that suffer from excessive backtracking, back-references, and other factors.

### The old way of terminating the matching process

Imagine providing a web service that allows people to supply regex patterns to test them against their desired data. How do you prevent someone from maliciously - or accidentally - bringing down your service with a poor pattern? To address this concern developers would need to handle the regex task asynchronously, measure the amount of time elapsed, and abandon the task if it exceeds a reasonable period of time.

Wouldn't it be great if some timeout mechanism was built-in? Well, now we have just that! This feature addresses [Connect feedback](http://connect.microsoft.com/VisualStudio/feedback/details/259625/regular-expression-regex-improvements-timeout-pattern-tester) from 2007 and it's great to see Microsoft continue to improve the regex engine.

## Show me what's new already!

Alright! First I'll cover the new pieces of the _Regex_ class, then I'll demonstrate with some code.

The .NET 4.5 _Regex_ class has been updated to include:

  * New overloaded constructors that accept a **_matchTimeout_** parameter of type _TimeSpan_. This applies to both instances of the _Regex_ class and static usage of the class. If a timeout isn't specified it will default to the application-wide default timeout value, if set, or the **_InfiniteMatchTimeout_** value otherwise.

  * Support for an application-wide default timeout value specified by setting the **"REGEX_DEFAULT_MATCH_TIMEOUT"** property via the [**AppDomain.SetData**](http://msdn.microsoft.com/en-us/library/system.appdomain.setdata%28v=VS.110%29.aspx) method.

  * A static **[_InfiniteMatchTimeout_](http://msdn.microsoft.com/en-us/library/system.text.regularexpressions.regex.infinitematchtimeout%28v=VS.110%29.aspx)** field member (_TimeSpan_) which indicates that a pattern matching operation shouldn't time out.

  * A **_MatchTimeout_** property (_TimeSpan_) representing the time-out interval of the current instance. When using the static methods this property can be accessed by handling the _RegexMatchTimeoutException_.

Should the _**matchTimeout**_ be exceeded, or invalid, the following exceptions will be thrown with the given messages:

  * [_**RegexMatchTimeoutException**_](http://msdn.microsoft.com/en-us/library/system.text.regularexpressions.regexmatchtimeoutexception%28v=VS.110%29.aspx): this exception is thrown when a timeout occurs. The message reads, "The RegEx engine has timed out while trying to match a pattern to an input string. This can occur for many reasons, including very large inputs or excessive backtracking caused by nested quantifiers, back-references and other factors."

  * _**ArgumentOutOfRangeException**_: according to the class' metadata this is thrown when "_**options**_ is not a valid _**RegexOptions**_ value" or when _"_**_matchTimeout_** is negative or greater than approximately 24 days." The latter part is what's new. Although it wasn't mentioned explicitly, I found that a value of zero is also considered invalid, which should come as no surprise.

Being aware of these two exceptions will be useful when working with the new feature. In addition, handling the [**TypeInitializationException**](http://msdn.microsoft.com/en-us/library/system.typeinitializationexception.aspx) is useful when using the application-wide timeout default. I'll demonstrate all of this in the subsequent sections that follow.

### Introducing a poor pattern

Consider this pattern: **`([a-z ]+)*!`**

This is a poor pattern with nested quantifiers that will cause excessive backtracking. It specifies a group that should be matched zero or more times (i.e., optional). The group contains a character class to match lowercase alphabets or the space character, one or more times. Finally, an exclamation mark should be matched.

Now, consider this input: _"The quick brown fox jumps"_

When I tested the pattern with this input it took an average of 11 seconds to process. I tried using [the full pangram](http://en.wikipedia.org/wiki/The_quick_brown_fox_jumps_over_the_lazy_dog) but it took way too long, so I stopped at the word "jumps" to get an idea of the processing time. As the string grows so will the time needed for the engine to complete it's pattern matching attempt. This pattern has an exponential complexity of O(2n).

If you're interested in the details of what makes this a poor pattern read up on [catastrophic backtracking](http://www.regular-expressions.info/catastrophic.html).

The code for the above pattern and input looks like this:

```cs
string input = "The quick brown fox jumps";
string pattern = @"([a-z ]+)*!";
bool result = Regex.IsMatch(input, pattern);
```

Try it out. I'll wait! Then try it with a longer input and continue reading this post. I suspect it'll still be running long after you're done reading.

### Limiting processing time with the matchTimeout parameter

Let's update the code to make it timeout after 4 seconds:

```cs
string input = "The quick brown fox jumps over the lazy dog.";
string pattern = @"([a-z ]+)*!";
var matchTimeout = TimeSpan.FromSeconds(4);
try
{
    bool result = Regex.IsMatch(input, pattern,
                                RegexOptions.None,
                                matchTimeout);
}
catch (RegexMatchTimeoutException ex)
{
    // handle exception
    Console.WriteLine("Match timed out!");
    Console.WriteLine("- Timeout interval specified: " + ex.MatchTimeout);
    Console.WriteLine("- Pattern: " + ex.Pattern);
    Console.WriteLine("- Input: " + ex.Input);
}

/* Output:
Match timed out!
- Timeout interval specified: 00:00:04
- Pattern: ([a-z ]+)*!
- Input: The quick brown fox jumps over the lazy dog.
*/
```

That's all there is to it! Now the regex engine will give up and throw an exception if 4 seconds elapse. Also notice the helpful properties accessible from the _RegexMatchTimeoutException_ object.

### Checking the specified duration with the MatchTimeout property

When using an instance of the _Regex_ class you have access to the _MatchTimeout_ property. In the following example I'll use a _StopWatch_ and compare the time taken to match a new sentence.

```cs
string input = "The English alphabet has 26 letters";
string pattern = @"\d+";
var matchTimeout = TimeSpan.FromMilliseconds(10);
var sw = Stopwatch.StartNew();
try
{
    var re = new Regex(pattern, RegexOptions.None, matchTimeout);
    bool result = re.IsMatch(input);
    sw.Stop();

    Console.WriteLine("Completed match in: " + sw.Elapsed);
    Console.WriteLine("MatchTimeout specified: " + re.MatchTimeout);
    Console.WriteLine("Matched with {0} to spare!",
                         re.MatchTimeout.Subtract(sw.Elapsed));
}
catch (RegexMatchTimeoutException ex)
{
    sw.Stop();
    Console.WriteLine(ex.Message);
}

/* Output:
Completed match in: 00:00:00.0007495
MatchTimeout specified: 00:00:00.0100000
Matched with 00:00:00.0092505 to spare!
*/
```

### Handling invalid matchTimeout durations

What happens when we specify an invalid _matchTimeout_ value? As mentioned earlier, an _ArgumentOutOfRangeException_ will be thrown when _matchTimeout_ is either:

  * Negative (see my comments on _Regex.InfiniteMatchTimeout_ next for an exception to the rule)

  * Zero

  * Greater than approximately 24 days

To see this in action, let's use the last case. I'm not sure how Microsoft decided on the ~24 day limit, but if you have a regex taking days to process I would question whether you're using the right tool for the job.

```cs
string input = "The quick brown fox jumps over the lazy dog.";
string pattern = @"([a-z ]+)*!";

// invalid timeout of 25 days
var matchTimeout = TimeSpan.FromDays(25);
try
{
    var re = new Regex(pattern, RegexOptions.None, matchTimeout);
    bool result = re.IsMatch(input);
}
catch (ArgumentOutOfRangeException ex)
{
    Console.WriteLine(ex.Message);
}

/* Output:
Specified argument was out of the range of valid values.
Parameter name: matchTimeout
*/
```

### To infinity... and beyond!

Oddly enough the _Regex.InfiniteMatchTimeout_ field has a negative _TimeSpan_ value of -00:00:00.0010000 (-1 ms) that, when passed as a _matchTimeout_ parameter, doesn't cause the _ArgumentOutOfRangeException_ to be thrown. Talk about being exceptional!

So what exactly is its purpose? As stated earlier it's used as a default value that indicates a match should not timeout, which is essentially the original pre-.NET 4.5  behavior. It takes effect only when the application-wide default value isn't set. Thus, it's quite redundant to pass in as a parameter.

To illustrate, these two regex instances share equivalent timeout values (when no application-wide default value is present):

```cs
string pattern = @"\d+";
var re = new Regex(pattern);
var reInfinite = new Regex(pattern, RegexOptions.None, Regex.InfiniteMatchTimeout);
Console.WriteLine(re.MatchTimeout == reInfinite.MatchTimeout);
// Output: True
```

## Application-wide default match timeout

To specify an application-wide default timeout value for all regex operations in an application domain you need to set the **"REGEX_DEFAULT_MATCH_TIMEOUT"** property. Any regex operation or instance declaration will then use the value assigned to that _AppDomain_ property.

### Setting the AppDomain default value

```cs
string input = "The quick brown fox jumps over the lazy dog.";
string pattern = @"([a-z ]+)*!";

// AppDomain default set somewhere in your application
var defaultMatchTimeout = TimeSpan.FromSeconds(2);
AppDomain.CurrentDomain.SetData("REGEX_DEFAULT_MATCH_TIMEOUT",
                                defaultMatchTimeout);

// regex use elsewhere...
var sw = Stopwatch.StartNew();
try
{
    bool result = Regex.IsMatch(input, pattern);
    sw.Stop();
}
catch (RegexMatchTimeoutException ex)
{
    sw.Stop();
    Console.WriteLine("Match timed out!");
    Console.WriteLine("Applied Default: " + ex.MatchTimeout);
}
catch (ArgumentOutOfRangeException ex)
{
    sw.Stop();
}
catch (TypeInitializationException ex)
{
    sw.Stop();
    Console.WriteLine("TypeInitializationException: " + ex.Message);
    Console.WriteLine("InnerException: {0} - {1}",
        ex.InnerException.GetType().Name, ex.InnerException.Message);
}

Console.WriteLine("AppDomain Default: {0}",
    AppDomain.CurrentDomain.GetData("REGEX_DEFAULT_MATCH_TIMEOUT"));
Console.WriteLine("Stopwatch: " + sw.Elapsed);
```

Woah! What's with all that code?! Most of the code is clear. A default value is set in the _AppDomain_ somewhere in your application. Then a regex operation is used without specifying a _matchTimeout_ value and the RegexMatchTimeoutException will be thrown. When the exception is caught it prints out the applied _MatchTimeout_, which should be the 2 seconds specified for the _AppDomain_ property. Finally the _AppDomain_ property is displayed, along with the elapsed _Stopwatch_ time. The output should be similar to this:

```cs
/* Output:
Match timed out!
Applied Default: 00:00:02
AppDomain Default: 00:00:02
Stopwatch: 00:00:02.0322906
*/
```

Next, notice the catch block that handles the _TypeInitializationException_. Re-run the code but this time use a negative (invalid) value for the _defaultMatchTimeout_ variable. When the _AppDomain_ property is invalid the _Regex_ class throws this type of exception and the output of the code above then resembles this:

```cs
/* Output:
TypeInitializationException: The type initializer for
'System.Text.RegularExpressions.Regex' threw an exception.
InnerException: ArgumentOutOfRangeException - Specified argument was out of the
range of valid values.
Parameter name: AppDomain data 'REGEX_DEFAULT_MATCH_TIMEOUT' contains an invalid
value or object for specifying a default matching timeout for
System.Text.RegularExpressions.Regex.
AppDomain Default: -00:00:02
Stopwatch: 00:00:00.0550294
*/
```

### Overriding the AppDomain default value

While you may want to use the application-wide default value in most cases, there are times when you want certain regex operations to use different values. Overriding the _AppDomain_ default is as easy as specifying the _matchTimeout_ parameter.

For example:

```cs
var defaultMatchTimeout = TimeSpan.FromSeconds(5);
AppDomain.CurrentDomain.SetData("REGEX_DEFAULT_MATCH_TIMEOUT",
                                defaultMatchTimeout);

string input = "The quick brown fox jumps over the lazy dog.";
string pattern = @"([a-z ]+)*!";

var sw = Stopwatch.StartNew();
try
{
    var matchTimeout = TimeSpan.FromSeconds(2);
    bool result = Regex.IsMatch(input, pattern, RegexOptions.None, matchTimeout);
    sw.Stop();
}
catch (RegexMatchTimeoutException ex)
{
    sw.Stop();
    Console.WriteLine("Match timed out!");
    Console.WriteLine("Applied Default: " + ex.MatchTimeout);
}

Console.WriteLine("AppDomain Default: {0}",
    AppDomain.CurrentDomain.GetData("REGEX_DEFAULT_MATCH_TIMEOUT"));
Console.WriteLine("Stopwatch: " + sw.Elapsed);

/* Output:
Match timed out!
Applied Default: 00:00:02
AppDomain Default: 00:00:05
Stopwatch: 00:00:02.0256260
*/
```

## Recognizing the underlying issues

While this new feature is great, it's important to be cognizant of the underlying issues. Look back at the reasons listed for poor regex performance and ponder over them.

I think this feature is ideal for people who are writing services or features that accept user input. It's now a breeze to put an end to potentially rampant patterns. A reasonable timeout duration could be set, or it may even be dynamically assigned based on upfront checks of pattern length and input length for flexibility.

That said, if you're the author of poorly performing patterns then using this as a crutch to fall back on isn't acceptable. Simply put, take regular expressions seriously and learn to write better patterns by understanding the shortcomings and characteristics of bad patterns.

## Conclusion: Default values, existing Regex utilization and guidance

By default the _Regex_ class will not timeout. So what should we do about previous uses of _Regex_ in our projects, if anything? The [MSDN documentation](http://msdn.microsoft.com/en-us/library/system.text.regularexpressions.regex%28v=VS.110%29.aspx) states:

> We recommend that you set a time-out value in all regular expression pattern-matching operations. For more information, see [Best Practices for Regular Expressions in the .NET Framework](http://msdn.microsoft.com/en-us/library/gg578045%28v=VS.110%29.aspx).

I have some reservations about doing that all the time. I suggest leaving them alone, for the most part. There's no need to hunt down all your regular expressions just to assign a timeout duration to them. That would entail identifying their current performance in order to avoid setting low timeout durations that would cause them to fail. Instead, focus on the patterns with poor performance, time critical usages, or areas where user input is used. If you're aware of problem areas, then by all means apply the _matchTimeout_ to them individually after determining reasonable timeout limits.

I would caution against specifying an _AppDomain_ level default timeout and walking away. Again, knowing your patterns and scenarios make a huge difference in what strategy to employ. An _AppDomain_ default is appropriate when you want to set an absolute maximum timeout limit for all your _Regex_ operations to prevent a pattern's performance from catching you by surprise. With that guard in place you should then identify any patterns you believe need more time and override those values directly. This could also present an opportunity to incorporate unit tests of your patterns to ensure timeouts occur within the expected interval, or that they pass successfully before the limit is reached.

Bear in mind that you'll want to add exception handling too. Handle the _RegexMatchTimeoutException_ to cover timeouts, and handle the _ArgumentOutOfRangeException_ when dynamically applying a _matchTimeout_ value.

Despite the addition of this feature, most operations execute fairly quickly, usually in the milliseconds to early seconds range. When determining reasonable timeout intervals the [MSDN documentation](http://msdn.microsoft.com/en-us/library/system.text.regularexpressions.regex.matchtimeout%28v=vs.110%29.aspx) suggests taking the following factors into consideration:

>   * The length and complexity of the regular expression pattern. Longer and more complex regular expressions require more time than shorter and simpler ones.
>   * The expected machine load. Processing takes more time on systems with high CPU and memory utilization.

To add to that advice, the length of the input is another factor to consider.

Overall I'm pleased with the addition of this feature and think it provides a simple approach to managing performance concerns without the need of writing ugly workarounds to address application responsiveness.
