---
title: Follow a specific user with Application Insights by setting AuthenticatedUserId
date: 2016-12-26 09:32:08
categories: 
    - Coding
tags:
    - Application Insights
    - Azure
    - Tracking and tracing
    - ASP.NET
    - Javascript
    - .NET
    - User tracking
thumbnail: /2016/12/26/Follow-a-specific-user-with-Application-Insights-by-setting-AuthenticatedUserId/thumbnail.jpg
---
In my latest project we embraced Application Insights as our logging and tracking platform. I am impressed by its capabilities and ease of use when hosting on Azure. It already has been very useful and it is free, because the amount of data we track is within 1 GB or 5M data points per month.

### User tracking
The only thing I felt was missing was (specific) user tracking. Out of the box AppInsights stores a user key with every tracked item, but this is a random value. This is good, because it lets you track and group all the telemetry of one user, but we don't know who that user is. We wanted to add a username or email to the telemetry so we could track a specific user.

### Why we wanted to track a specific user
There is for me no doubt Application Insights is very useful, only last week I fixed 3 exceptions before the user's could let us know things were broken, because they showed up in App Insights. Also this week I noticed a javascript error in a browser version we don't test ourselves because of time constrains. An error we otherwise would have missed. So both clear wins!

A good example, why tracking the user is useful, was a user who said there was a bug in the system. We couldn't reproduce the issue, but by looking at his session we figured out he was using the system differently then we anticipated. It did spark a discussion if the system was clear enough, but it turned out not to be a bug. A good thing to know and it was very useful and a time saver that we could track the user.

### Connecting your user system with Application Insights
Application Insights out of the box generates a random value because it doesn't know about your users. You might be using Active directory, ASP.NET Identity, a custom solution or something else, so you have to link those up yourself. 

App Insights can track server and client side. This means it tracks items on the server within ASP.NET and it tracks client side in the javascript running in the users browsers. The server side tracks for example Requests, Dependencies and Exceptions. On the client it tracks for example page views and user events like a button click. On all those request we wanted to add the username.

### How to track the user server side
Implement the ITelementryInitializer interface. The Initialize method is called on every telemetry item that is tracked. So it is important to keep the method very simple to not slow down your application. It will be called a lot. The easiest, and what we ended up doing, is set the CurrentPrincipal Identity Name as the AuthenticatedUserId. AuthenticatedUserId is a standard property available on every tracked item and in our system the Identity.Name is set to the users username (which is their email address). This is what the class looks like:

{% codeblock lang:CSharp %}
public class AppInsightsInitializer : ITelemetryInitializer
{
    public void Initialize(ITelemetry telemetry)
    {
        if (Thread.CurrentPrincipal != null && 
            Thread.CurrentPrincipal.Identity != null)
        {
            telemetry.Context.User.AuthenticatedUserId = 
                          Thread.CurrentPrincipal.Identity.Name;
        }
    }
}{% endcodeblock %}When you created this Initializer you need to load it on application load. You can do this by adding this to you Startup.cs or Global.asax:
{% codeblock lang:CSharp %}
TelemetryConfiguration.Active.TelemetryInitializers
                                  .Add(new AppInsightsInitializer());
{% endcodeblock %}
### How to track the user on the client
For client side Application Insights tracking we already added some javascript to every page. We set the user by calling the setAuthenticatedUserContext on the appInsights object. This method sets the same AuthenticatedUserId. Here we also take the Identity Name as the value:
{% codeblock lang:Javascript %}
var appInsightsUserName = '@User.Identity.Name.Replace("\\", "\\\\")';
appInsights.setAuthenticatedUserContext(
                        appInsightsUserName.replace(/[,;=| ]+/g, "_"));
appInsights.trackPageView();
{% endcodeblock %}Now all your Application Insights telemetry contains the username of the user (when that user is logged in at least). Happy user tracking!

More information can be found here:
https://docs.microsoft.com/en-us/azure/application-insights/app-insights-api-custom-events-metrics
