---
title: How to deal with time (in .NET and on Azure)
date: 2016-05-17 16:28:43
categories: 
    - .NET Code
tags:
    - .NET
    - DateTime
    - Time
    - Azure
---
Handling time in .NET applications, it seems straight forward ("just use the .NET `DateTime` object") and in some scenario's it also is, but not for everything. In your local hobby project you will be fine, but I am sure everyone venturing further than that, will have experienced that working with time in .NET is not always so easy and/or logical.  

I will cover 3 different scenarios that I have encountered and how we solved those. This is by no means a complete list, but I do think they cover the main scenarios:
1.  A locally developed website used by people in the same country and hosted in that country
2.  A relatively small application, used by people in the same country, but hosted on Azure
3.  An application with user from all over the world

![](clock-407101_1280.jpg)

### 1. A locally developed website used by people in the same country and hosted in that country
This scenario is why I think not everyone runs into trouble with `DateTime` when they first start out developing .NET applications. If we make the assumption that the development machine, the user machines and the server (host) machine are all configured with the same time zone, the .NET DateTime object works fine.

You don't really need time conversion in your application, which makes the application definitely less complex. Yay for you! There are some things to consider though:
*   Does your time zone have summer and winter time? If so what happens in that hour that overlaps each year? Will this cause a problem in your application? It might for example mix up events occurring in the hour before the switch and the hour after. Is this a problem? If not, don't worry to much about it, I am a big proponent of lean development. Leave it be for now. But a possible solution in this situation would be to store time in UTC time. This makes it a little bit more complex, but will solve those problems. You can use the build-in ToUniversalTime and ToLocalTime on the DateTime object to do this.
*   What happens when one of your users wants to use the application when he goes to another time zone? This is not a problem if you can tell your user he has to input the time based on your applications time zone, but of course that is not very user friendly, so it is something to consider. To solve this your application will have to implement scenario 3. Your product owner will have to decide if that investment is worth the money.


### 2. A relatively small app, used by people in the same country, but hosted on Azure
So this scenario is why I ran into trouble with `DateTime`. My application is for users in Peru, so I only wanted to convert to the Peruvian time zone from UTC and the other way around. Scenario 3 was overkill in this situation, so I was looking for a simpler solution. To make it confusing, my development machine was set in local Peruvian time and the server the application was hosted on was in UTC (Azure). So the application responded differently on my development machine compared to Azure. Of course differences between development and productions are unwanted, but I think in this case for most people unavoidable. Who sets his development machine in UTC time (let me know!)? Some people maybe, but everyone who also does normal work on there computer can't. Another case for automated testing!

**So how can you handle these situations?**
If you try to solve this problem with the standard `DateTime` object you run into a problem. For example, the user needs to select a date or time, so you make a select field (with a nice datetimepicker) and store the datetime in a DateTime object in your MVC model. On the server you immediately convert the datetime to UTC. Sounds easy, but wait...

My first instinct was to do something this (like scenario 1):
{% codeblock Basic (but wrong) conversion lang:CSharp %}
    //This is the same thing that happens when the MVC model is filled
    var date = DateTime.Parse( "2016-5-16 18:59:00"); 
    var utc = date.ToUniversalTime();
{% endcodeblock %}
And this works on my development machine, but fails on Azure. `DateTime` interprets the datetime based on the computer time zone, because the Kind property is set to Unspecified (during model binding). So on my development PC it uses a 5 hour UTC offset (based on my computers time zone), but on Azure the UTC offset is 0 (because Azure servers run on UTC time). So where my local machines stored the right UTC time in the database, on Azure the time the user inputted was directly stored as UTC in the database.

To solve this you have to use a specific time zone to convert the value:
{% codeblock Convert time with timezone lang:CSharp %}
    //This is the same thing that happens when the MVC model is filled
    var date = DateTime.Parse( "2016-5-16 18:59:00"); 
    TimeZoneInfo tzi = TimeZoneInfo.FindSystemTimeZoneById("SA Pacific Standard Time");
    var utc = TimeZoneInfo.ConvertTimeToUtc(date , tzi);
{% endcodeblock %}

This means you need to know the time zone of the user. If you have an application where only one time zone is required this can be a config setting.

### 3. An application with users from all over the world
Let's say you are building twitter. Every user of twitter wants to see time in his time zone, and even if he goes overseas he should see the correct time. There are 2 ways to approach this problem: 

1.  Always use the time from the browser the user is currently browsing from (via javascript) to show the correct time.
2.  Save the user time zone in a user profile


In both cases you want to store time in UTC so wherever the user is from, events are always ordered in the right way. The first approach works very well when you have a javascript client, like an AngularJS website, because browser time will always be available. All your server code will use UTC time and on the client you can convert to the browser time zone. This has an advantage that it also corrects the time when a user is traveling (assuming he/she changes the computer/cellphone time of course). 

When doing anything with time, you make your own life so much easier when using momentJS (http://momentjs.com/). With momentJs you can do the conversion like this:
{% codeblock Conversion with momentJS lang:Javascript %}
    var timeZoneName = "America/Lima";
    var originalUtcDate = moment.utc();
    var convertedDate = originalUtcDate.tz(timeZoneName);
    var utcDate = convertedDate.utc();
{% endcodeblock %}
When you use ASP.NET MVC for example (or another traditional website) it is harder to get access to the browser time. So here it is easier to store the time zone of the user in his/her profile so you can access it on the server. In this case the user will have to change the time zone on the website when he/she travels. 

When you know the timezone the user is in, you can convert the time from and to UTC in C# like this:
{% codeblock Convert time with timezone lang:CSharp %}
    TimeZoneInfo tzi = TimeZoneInfo.FindSystemTimeZoneById("SA Pacific Standard Time");
    var originalUtcDate = DateTime.UtcNow;
    var convertedDate = TimeZoneInfo.ConvertTimeFromUtc(originalUtcDate, tzi);
    var utcDate = TimeZoneInfo.ConvertTimeToUtc(convertedDate, tzi);
{% endcodeblock %}
Another option, which I haven't tried myself, but the idea sounds very interesting. You can still only use UTC time in MVC, and use javascript to convert times in the browser to the correct local time. This means identifying all datetime fields on page load and replace the values with corrected values and hook into form post events to change the values on post as well. It would be possible to write generic functions to do this, which would make life a lot easier and less prone for mistakes. 

### Summary
TLTR, some best practices for working with `DateTime` in .NET:
*   Always store datetime information in the database in UTC
*   Know which time zone the user is working in. Make it explicit in some way (read the articles for options).
*   When working with javascript apps (for example AnjularJS), use the browser time and work on the server and on the wire always in UTC. This is a great clear boundary.
*   In MVC websites, this is harder, but I would advise converting to UTC as fast as you can. A good option is using client side javascript for this (because it makes it possible to use the browser time to convert to UTC) otherwise as soon as you are on the server (for example only use user time in the Model).
*   Understand that time conversion is super tricky, definitely when dealing with different time zones. Use official tested frameworks to do this. You can use momentJS (http://momentjs.com/) for javascript and/or Noda Time (http://nodatime.org/) in C# if you do any kind of complex datetime conversion math.
*   If you are interested in more best practices, see [this](https://msdn.microsoft.com/en-us/library/ms973825.aspx) comprehensive guide.

This is not a complete guide, but a view in the complexities of time zone programming. If you have anything to add, do not agree or have other scenario's to add, please leave a comment.
<style type="text/css">.article-entry li{ margin-left: 2.2em; list-style-position: outside; }</style>