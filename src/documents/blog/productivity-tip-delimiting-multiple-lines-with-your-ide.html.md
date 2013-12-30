---
date: 2012-01-11 17:47:36+00:00
layout: post
title: 'Productivity tip: delimiting multiple lines with your IDE'
tags: ['post','productivity','regex']
---

During development I've had the need to delimit a number of lines with a character. Sometimes these lines are numerous and the task is mind-numbingly tedious if I have to sit there and do it manually.

Imagine you're working with SQL and have a list of ProductId values on separate lines in your clipboard:

> 1

> 12

> 123

> 1234

You want to include these values when using the IN keyword:

```sql
SELECT * FROM Products
WHERE ProductId IN (...)
```

The goal is to place commas before the numbers, or after the numbers, as shown below.

```sql
-- commas before
SELECT * FROM Products
WHERE ProductId IN (1
,12
,123
,1234)
```
```sql
-- commas after
SELECT * FROM Products
WHERE ProductId IN (1,
12,
123,
1234)
```

This is the order most people take:

  1. Paste numbers between the parentheses
  2. Position cursor at the start (or end) of the line with the arrow keys (bad) or <kbd>Home</kbd> / <kbd>End</kbd> key (better)
  3. Insert comma
  4. Move to the next line
  5. Repeat N - 1 times

There's got to be a better way to do this right? Right!

The two techniques I'll cover in this post are:

  1. Column mode selection
  2. Find/Replace using regular expressions

### Column mode selection

The typical selection mode is known as _continuous stream selection_, which is the default selection via the mouse or is performed by using the <kbd>Shift</kbd> **+ arrow** keys. The other mode is **column mode**, or **box mode**. It lets you select text in columns with a rectangular portion for vertical editing. Once the columns are selected you have the option of inserting, deleting, copying, or pasting text. It's also possible to overwrite text (i.e., overstrike) by hitting the Insert key and typing new text.

<p class="text-center">
    ![Stream and Column selection modes](/images/StreamAndColumnSelectionModes.png)
</p>

Some IDEs and text-editors support column mode, such as Visual Studio 2010 and Notepad++. In fact, prior versions of Visual Studio supported it, but they didn't support text insertion, pasting, or zero-length boxes, which are [new features introduced in VS 2010](http://msdn.microsoft.com/en-us/library/dd465268.aspx). Thus, it was only good for copying and deleting text. Microsoft SQL Server Management Studio (SSMS, using SQL Server 2008) seems to have the limited pre-VS 2010 support for this, which was the inspiration behind this post's second technique.

#### Keyboard approach:

  1. Place the cursor at the beginning of the line.
  2. Press and hold the <kbd>Shift</kbd> + <kbd>Alt</kbd> keys, then move the cursor with any **arrow key**. You will see the cursor flashing on each line you've selected.
  3. Type the desired character or text to prefix or delimit the lines with. For this example it's a comma: `,`.

#### Mouse approach:

  1. Place the cursor at the beginning of the line.
  2. Press and hold the <kbd>Alt</kbd> key, then click the left mouse button and move the cursor over the desired text.
  3. Modify text as desired.

To clarify, for the purposes of this example the cursor is placed at the beginning of the line. However, column mode can be used anywhere in the text, even in the middle of a word.

With regards to the SQL statement earlier, delimiting at the beginning of the lines is probably the best option when using this feature since the text is lined up properly. The end of your lines usually won't line up since they might have different lengths. The following screenshot demonstrates selecting the columns and the result after adding commas.

<p class="text-center">
    ![Column selection and result of inserting commas](/images/ColumnSelection.png)
</p>

There are a number of places where this technique could be useful. In the earlier screenshot showing the stream and column modes, the Hungarian notation could be eliminated easily. Just select the column of "i" characters and hit Backspace. Voila! Consider another scenario where you want to add or change the access modifier for a bunch of properties on a class, making them all `public`... column mode to the rescue!

<p class="text-center">
    ![Column selection to add access modifiers to class properties](/images/ColumnSelectionPersonClass.png)
</p>

For additional information refer to:

  * Notepad++ - [Column edit mode](http://npp-community.tuxfamily.org/documentation/notepad-user-manual/editing/column-mode-editing)
  * Visual Studio 2010 - [How to: Select and Change Text](http://msdn.microsoft.com/en-us/library/729s2dhh.aspx)

### Find/Replace using regular expressions

In case your IDE of choice doesn't support column selection, you can still pull this off if you're not averse to learning a tiny amount of regex. When I say "tiny" I really mean it. All it takes is one regex metacharacter, and you have two to choose from depending on where you want to place the delimiter.

<p class="text-center">
    [![Regex?  oh noes!!!](http://images.cheezburger.com/completestore/2012/1/5/62311133-3d91-4df8-aedb-566c75a9ef22.jpg)](http://cheezburger.com/View/5656160768)
</p>

To solve this task use the IDE's Find/Replace dialog and select the regex option. The two metacharacters of interest are:

  * **^**: the caret character matches the position at the beginning of the line
  * **$**: the dollar sign matches the position at the end of the line

These are known as [anchors](http://www.regular-expressions.info/anchors.html) since they match at specific positions.

To place the commas before the numbers, use the caret. Otherwise, use the dollar sign to place them after the numbers. The replacement character will be a comma, and you should select the lines to delimit then restrict the replacement to the active selection.

The following screenshots show the find/replace dialog setup in Microsoft Visual Studio 2010 before the replacement, and the result after the replacement.

**Before:**
<p class="text-center">
    ![Delimiting the beginning of lines via regex](/images/IdeRegexDelimitLineStart.png)
</p>

**After:**
<p class="text-center">
    ![Result of delimiting the beginning of lines via regex](/images/IdeRegexDelimitLineStartResult.png)
</p>

Similarly, it's possible to place the commas at the end of the lines using the dollar sign metacharacter. The following screenshots demonstrate this approach in Notepad++.

**Before:**
<p class="text-center">
    ![Delimiting the end of lines via regex](/images/IdeRegexDelimitLineEnd.png)
</p>

**After:**
<p class="text-center">
    ![Result of delimiting end lines](/images/IdeRegexDelimitLineEndResult.png)
</p>

Beware that while most IDEs and text-editors support regex, some only support a subset of metacharacters or may use different metacharacters completely. The good news is the two metacharacters I've introduced are standard amongst most regex flavors, which should make this tip universally applicable. I've used this tip in Microsoft Visual Studio, Notepad++, LINQPad, and SSMS.

Note, however, that SSMS exhibits an odd behavior (bug?) when using the caret to delimit at the beginning of the line. It skips the first selected line, resulting in 2 occurrences being replaced instead of the expected 3, per my example. This isn't such a big deal, since at that point all you need to do is manually do the work on one line. Alternately, to get around this, I include the line before the target line to delimit in my selection. That means including the line that starts with "WHERE" so the replacement skips that line and correctly delimits the remaining lines. That said, SSMS works fine when using the end of line delimiting approach with the dollar sign.

### Closing thoughts

Obviously column mode is much simpler than using find/replace and regex. If you have that option, use it. Nonetheless, regex is extremely useful for other scenarios where you want to locate a string or series of characters in a certain pattern, then not only add a prefix or suffix to it, but re-use portions of the original input in the replacement. To do so, knowledge of regex comes in handy and can let you pull off such complex text manipulation tasks. Perhaps that's a post for another day!

For the purposes of this post, however, I've only covered delimiting at the start and end of a string and detailed a comparable one to one solution for the column mode and regex approaches.
