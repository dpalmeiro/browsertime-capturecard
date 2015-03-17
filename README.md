# It's browser time!
[![Build status][travis-image]][travis-url]
[![Downloads][downloads-image]][downloads-url]
[![Stars][stars-image]][stars-url]

Access the Web Performance Timeline, from your browser, in your terminal!

Browsertime allows you to:
 1. Query timing data directly from the browser, to access [Navigation Timing](http://kaaes.github.io/timing/info.html), [User Timing](http://www.html5rocks.com/en/tutorials/webperformance/usertiming/),
[Resource Timing](http://www.w3.org/TR/resource-timing/), first paint and [RUM Speed Index](https://github.com/WPO-Foundation/RUM-SpeedIndex).
 1. Generate [HAR](http://www.softwareishard.com/blog/har-12-spec/) files, generated by running a [BrowserMob Proxy](https://github.com/lightbody/browsermob-proxy) instance.
 2. Query custom Javascript in the browser and get statistics for each run.

Data from Browsertime is included in speed reports generated by [sitespeed.io](http://www.sitespeed.io).


# Table of Contents

- [Browsers](#browsers)
- [A simple example](#a-simple-example)
- [Digging deeper](#digging-deeper)
	- [Choose when to end your test](#choose-when-to-end-your-test)
	- [Fetch your own metrics from the browser](#fetch-your-own-metrics-from-the-browser)
	- [Simulate connection types](#simulate-connection-types)
	- [Basic Auth](#basic-auth)
	- [Request headers](#request-headers)
	- [Fake the user agent](#fake-the-user-agent)
- [Installation](#installation)
- [Authors](#authors)
- [Copyright and license](#copyright-and-license)

# Browsers
Browsertime supports Chrome, Firefox, IE (Windows only), Safari (8.x and will not generate a complete HAR) and PhantomJS (2.0 or later, however we use PhantomJS through Selenium with limited functionality).

# A simple example
```bash
> browsertime -u http://www.browsertime.net
```

Load www.browsertime.net in Chrome three times. Results are stored in a json file (www.browsertime.net.json) with the timing data, and a har file (www.browsertime.net.har).

# Digging deeper
```bash
> browsertime -u http://www.sitespeed.io -n 9 -b firefox -w 600x800 --filename sitespeed.json --harFile sitespeed.har
```

Start firefox and load www.sitespeed.io nine times, to get a better statistical sample. Statistical median, percentiles and more are outputted to *www.sitespeed.io.json*, including all individual measurement values. The window size is fixed at 600 times 800 pixels.

Using the excellent tool [jq](http://stedolan.github.io/jq/), query the timing data to find the 99th percentile of the pageLoadTime metric; 4061 milliseconds.

```bash
> jq '.default.statistics[] | select(.name == "pageLoadTime").p99 ' -r  www.sitespeed.io.json
> 4061
```

All available options for controlling Browsertime are documented when running 
```bash
> browsertime -h
```

## Choose when to end your test
By default the browser will collect data until the *window.performance.timing.loadEventEnd* happens. That is perfectly fine for most sites, but if you do ajax loading and you mark them with user timings, you probably want to include them in your test. Do that by changing the script that will end the test (*--waitScript*). When the scripts returns true the browser will close or if the timeout time (default 60 seconds) will be reached:
```bash
> browsertime -u http://www.github.com --waitScript 'return window.performance.timing.loadEventEnd>0'
```

## Fetch your own metrics from the browser
You can collect your own metrics in the browser by supplying a directory with jacascript files. Each file need to return a metric/value and it will be picked up and returned in the JSON. If you return a number, statistics will automatically be generated for the value (like median/percentiles etc). Check out the [scripts](https://github.com/tobli/browsertime/tree/master/lib/scripts/metrics) we use.

Say we have a folder called *scripts* and in there we have one file called *scripts.js* that checks how many javascript that is loaded. The script looks like this:

```javascript
return document.getElementsByTagName("script").length;
```

Then to pick up the script, run like this:

```bash
> browsertime -u http://www.github.com --customScripts scripts
```

The basename of the file *script* will be used as the metric name in the json.

## Simulate connection types
You can choose the speed by simulating different connection types. By default you can choose between *mobile3g*, *mobile3gfast*, *cable* or *native* (default).
```bash
> browsertime -u http://www.github.com --connection cable
```

If you need to have a specific connection not listed in the above, you can configure it yourself with *connectionRaw* (and change $X, $Y and $Z to what you need.
```bash
> browsertime -u http://www.github.com --connectionRaw {downstreamKbps: $X, upstreamKbps: $Y, latency: $Z}
```

## Basic Auth
You can set basic auth user & password like this:
```bash
> browsertime -u http://stage.example.com --basicAuth username:password
```

## Request headers
Set request headers by supplying a JSON:
```bash
> browsertime -u http://stage.example.com --headers {name:value,name2:value2}
``` 

## Fake the user agent
Using Firefox and Chrome you can fake your user agent. Default is using the current browsers user agent.
```bash
> browsertime -u http://stage.example.com --userAgent "My super user agent string"
``` 

# Installation
Browsertime is built using [Node.js](http://nodejs.org), and installed via npm.
```bash
> npm install browsertime -g
```

# Authors
* Tobias Lidskog ([@tobiaslidskog](https://twitter.com/tobiaslidskog)): https://github.com/tobli
* Peter Hedenskog ([@soulislove](https://twitter.com/soulislove)): https://github.com/soulgalore

Follow Browsertime on Twitter: [@browsertime](https://twitter.com/browsertime)

# Copyright and license

Copyright 2014 Tobias Lidskog & Peter Hedenskog under [the Apache 2.0 license](LICENSE).

[travis-image]: https://img.shields.io/travis/tobli/browsertime.svg?style=flat-square
[travis-url]: https://travis-ci.org/tobli/browsertime
[stars-url]: https://github.com/tobli/browsertime/stargazers
[stars-image]: https://img.shields.io/github/stars/tobli/browsertime.svg?style=flat-square
[downloads-image]: http://img.shields.io/npm/dm/browsertime.svg?style=flat-square
[downloads-url]: https://npmjs.org/package/browsertime
