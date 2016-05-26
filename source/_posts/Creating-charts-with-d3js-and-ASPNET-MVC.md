---
title: Creating charts with d3.js and ASP.NET MVC
date: 2016-05-25 08:24:47
categories: 
    - Coding
tags:
    - Javascript
    - D3.js
    - Charts
    - Graphs
    - Linechart
    - Barchart
    - ASP.NET
thumbnail: /2016/05/25/Creating-charts-with-d3js-and-ASPNET-MVC/chart.JPG
---
For a recent project I needed to create a line chart and a bar chart. Previously I used the ASP.NET chart controls, but in the new ASP.NET Core the chart control is not available anymore, so I went looking for something new. Because of the many single page applications build in javascript these days I figured a javascript based solution would be the best investment for the future. With client computers and browsers being fast enough, there really is no need anymore to generate charts on the server.  After some research I choose [D3.js](https://d3js.org/).

> "D3.js is a javascript library for producing dynamic, interactive data visualizations in web browsers. It makes use of the widely implemented SVG, HTML5, and CSS standards. It is the successor to the earlier Protovis framework." - Wikipedia

D3.js is a highly flexible and powerful library to build a variety of different data visualizations. But the downside of being so powerful is that it is not so easy to understand at first. That is why I wanted to make this blog post. I am going to assume you are a developer like me, so you have knowledge of HTML, CSS, Javascript and for the .NET parts also knowledge of ASP.NET. I will walk you through creating a bar chart and a line chart. And will explain how to get the data for your chart from the server. After that you should have a basic understanding of D3.js, to also be able to build other visualizations. See other visualizations [here](https://github.com/d3/d3/wiki/Gallery). 

### How to make a bar chart
To build a chart we start with a basic page, with the d3.js reference and a [SVG](http://www.w3schools.com/html/html5_svg.asp) (Scalable Vector Graphics) element. This SVG is used to draw the chart. With javascript we give the SVG a width and height and we store those in a variable, because we will need those later. We also have a set of data that we can use to draw. Later we will take the data from a JSON call.
{% codeblock lang:HTML %}
    <script src="https://d3js.org/d3.v3.min.js" charset="utf-8">
    <svg id="barChart"></svg>
    <script>
    var data = [ 50,90,30,10,70,20];

    var w = 500;
    var h = 100;

    var svg = d3.select("#barChart")
                .attr("width", w)
                .attr("height", h);
    </script>
{% endcodeblock %}That is the basic setup, we continue with drawing the bars:
{% codeblock lang:Javascript %}
    svg.selectAll("rect")
        .data(data)
        .enter()
{% endcodeblock %}This takes the data and for every item in the array (basic number or complex type) makes a rectangle. After the enter() function every other chained function is called for every rectangle. Because every rectangle needs an x and y (start position coordinate) and a width and height we will add those like this:
{% codeblock lang:Javascript %}
    .attr("x", 0)
    .attr("y", 0)
    .attr("width", 20)
    .attr("height", 100);
{% endcodeblock %}But this only gives us what looks like 1 rectangle (it are actually 6 rectangles on top of each other), because the values obviously are bar specific. First we change the x for every rectangle:
{% codeblock lang:Javascript %}
    .attr("x", function(d, i) {
        return i * 21;  //Bar width of 20 plus 1 for padding
    })
{% endcodeblock %}This moves every bar next to the previous bar (the bars are 20 pixels wide, plus 1 pixel padding inbetween). Then we change the height so it has the height of the value:
{% codeblock lang:Javascript %}
     .attr("height", function(d) {
        return d;  //Just the data value
    });
{% endcodeblock %}But now the bar is upside down, so we correct the y to start so all the bars line out on the bottom:
{% codeblock lang:Javascript %}
     .attr("y", function(d) {
          return h - d;  //Height minus data value
      })
{% endcodeblock %}Here is what we have so far, you can play with the javascript to see what happens with the bars:<a class="jsbin-embed" href="http://jsbin.com/wubufu/5/embed?html,output">JS Bin on jsbin.com</a><script src="http://static.jsbin.com/js/embed.min.js?3.35.12"></script>
I added some color to the chart with the fill attribute, just to make it a little nicer. You can use javascript or CSS to style your chart (later you will see a css example).

The example is nice, but this only works because the data matches the pixels of the chart. What if they don't, because that is like.. always? Well then you use [scales](https://github.com/d3/d3/wiki/Quantitative-Scales), a functions to map from an input domain to an output range. To be able to show a full bar chart we make the data a bit more complex:
{% codeblock lang:Javascript %}
  var data = [ {  Product: "Shoes", Count: 5   },
        {  Product: "Shirts",  Count: 9  },
        {  Product: "Pants",  Count: 3   },
        {  Product: "Ties",  Count: 1  },
        { Product: "Socks",  Count: 7  },
        {  Product: "Jackets",  Count: 2  }];
{% endcodeblock %}Probably a more realistic dataset.

So we make scales, an ordinal scale ([more info here](https://github.com/d3/d3/wiki/Ordinal-Scales#ordinal_rangeBands)) for the bars, and a linear scale for the height of the bars:
{% codeblock lang:Javascript %}
    //An ordinal scale, to support the bars, we choose 
    var x = d3.scale.ordinal()
        .rangeRoundBands([width, 0], 0.1); 

    //I think this makes a lot of sense (just a default scale converter)
    var y = d3.scale.linear()
        .range([0, height]); 
{% endcodeblock %}And we add the "mapping", the domain:
{% codeblock lang:Javascript %}
    //The x domain is a map of all the Products names
    x.domain(data.map(function(d) {  return d.Product; }));
    //The y domain is a range from the maximal (Count) value in the array until 0
    y.domain([d3.max(data, function(d) { return d.Count;  }), 0]);
{% endcodeblock %}Then we can use that information to set the right x,y,width,height info for the bars. You use x() and y() functions for that. The rangeBand function is to help set the width for the bars:
{% codeblock lang:Javascript %}
    .attr("x", function(d) {
        //the x function, transforms the value, based on the scale
        return x(d.Product); 
    })
    //The rangeBand() function returns the width of the bars
    .attr("width", x.rangeBand()) 
    .attr("y", function(d) {
        return y(d.Count); //the y function does the same
    })
    .attr("height", function(d) {
        return height - y(d.Count);
    });
{% endcodeblock %}Now you have a fully working bar chart (with correct scaling):
<a class="jsbin-embed" href="http://jsbin.com/kixaqa/8/embed?html,output">JS Bin on jsbin.com</a><script src="http://static.jsbin.com/js/embed.min.js?3.35.12"></script>
This is a nice start, but I think most people would like to add some axis (see the inline comments for more info):
{% codeblock lang:Javascript %}
    var xAxis = d3.svg.axis() //Create an axis
        .scale(x) //scale the axis
        .orient("bottom"); //this is where the labels will be located

    var yAxis = d3.svg.axis()
        .scale(y)
        .orient("left")
        .tickFormat(d3.format("d")) //Ticks are the divisions on the scale. 
        .tickSubdivide(0); //Here we want to see only whole numbers on the axis

    svg.append("g")
        .attr("class", "y axis")
        .call(yAxis);

    svg.append("g")
        .attr("class", "y axis")
        .attr("transform", "translate(0," + height + ")")
        .call(xAxis)
        .selectAll("text") //In some cases the labels will overlap
        .attr("transform", "rotate(90)") //so you might for example want to rotate the label's so they are vertical
        .attr("x", 0) //After that you might have to do some finetuning to align everything the right way:
        .attr("y", -6)
        .attr("dx", ".6em")
        .style("text-anchor", "start");
{% endcodeblock %}And now we have a full chart (I also added some CSS styling):
<a class="jsbin-embed" href="http://jsbin.com/kixaqa/6/embed?html,output">JS Bin on jsbin.com</a><script src="http://static.jsbin.com/js/embed.min.js?3.35.12"></script>
Or as an extra example, the same data in a bar chart with [horizontal bars](http://jsbin.com/parase/1/edit?html,output). I wanted to share this example as well, because it turned out to be a bit more complex then I expected. Comparing them is a good way to see if you understand D3.js
### How to make a line chart
Another very common chart is the line chart. I build on top of what we learned with the bar chart, so I assume you understand the scaling:
{% codeblock lang:HTML %}
  <svg id="lineChart"></svg>
  <style>
    .line {
      fill: none;
      stroke: steelblue;
      stroke-width: 2px;
    }
  </style>
<script>

  var data = [50,90,30,10,70,20];

  var width = 500;
  var height = 100;

  var svg = d3.select("#lineChart")
              .attr("width", width)
              .attr("height", height);

  var x = d3.scale.linear()
  .range([0, width]);

  var y = d3.scale.linear()
  .range([height, 0]);

  x.domain([0, data.length]);
  y.domain([0, d3.max(data, function (d) { return d; })]);


        var line = d3.svg.line()
            .x(function (d, i) { return x(i); })
            .y(function (d) { return y(d); });

        svg.append("path")
            .datum(data)
            .attr("class", "line")
            .attr("d", line);
  </script>
{% endcodeblock %}This results in this line chart:
<a class="jsbin-embed" href="http://jsbin.com/zezumeg/8/embed?html,output">JS Bin on jsbin.com</a><script src="http://static.jsbin.com/js/embed.min.js?3.35.12"></script>
Very basic, but a line chart. Some things of note for the chart example:
* The scales are both linear
* The domains are set to size of the array and to the max value in the array
* The line is drawn by plotting the index of the array against the value in the array
* Then we add the line to the svg, as a path
* If you do not add any style for the line, it will look a bit strange, because it will fill the object by default (just try it out to see, remove the style block in the JSBin example), so normally you will add a style.
* Of course you can also add axis to this if you want, in the same way as with the bar chart.

Now the only thing left is styling your charts to make them look great! 
### Get data via an JSON call (ASP.NET MVC)
Mmost of the time the information for the chart comes from a database on the server. Although you could generate the javascript to create the data array, a cleaner solution is to make an JSON call to fetch the data. D3.js includes a perfect function to do this:
{% codeblock lang:Javascript %} 
    d3.json("MyController/MyAction", function (data) {
        //Here you have data available, an object with the same structure 
        //as the JSON that was send by the server.
    });
{% endcodeblock %}In ASP.NET Core 1.0 the function that will be called should look like this:
{% codeblock lang:CSharp %}
    public ActionResult MyAction()
    {
        return Json( new[] {
            new { Product = "Shoes" , Count = 5 },
            new { Product = "Shirts" , Count = 9 },
            new { Product = "Pants" , Count = 3 },
            new { Product = "Ties" , Count = 1 },
            new { Product = "Socks" , Count = 7 },
            new { Product = "Jackets" , Count = 2 }
        });
    }
{% endcodeblock %}And with that you have a complete chart with data from the server. If you need an "almost no development skills", or a more indepth tutorial for D3.js you can also look [here](http://alignedleft.com/tutorials/d3). Let me know if you have any questions. Happy charting! 
<style type="text/css">.article-entry li{ margin-left: 2.2em; list-style-position: outside; }</style>