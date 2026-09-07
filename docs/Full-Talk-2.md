[00:00:00] 

Hey everybody, welcome to my talk on CloudKit as your backend. So before we get started, let's talk about what exactly is CloudKit. 

Let's travel back to 2014, and WWDC 2014 to be exact

I don't know if you remember, but this was actually the WWDC that introduced us to Swift, which is really cool. also there's some interesting announcements and partnerships at WWDC 2014. Some of them didn't work out so well. but it also gave us the introduction to CloudKit. and the idea of CloudKit was basically providing that back end of data and logic that you'd want for a-an application that needed storage and logic and database and search and notifications and all that stuff [00:01:00] So if you haven't done a CloudKit app before, here's just a brief introduction.

there's a setup process which you can do in Xcode that will allow you to go ahead and just add, CloudKit to your, bundle entitlements, and that'll also create what's called a container, which is your storage for different records and stuff. so if you wanna set up your records, you can do this in the CloudKit console.

just go ahead and enter a new record, and then in your record, you can go ahead and set up different fields and field types. And you can see here the different options available, and give that field a name. So you can set up a string, a integer, a double, bytes, a date, location, reference asset, and a list.

you can do this [00:02:00] through your terminal or command line if you wanna script this stuff out. There's actually a schema format you can use, to set up your CloudKit records. And then if you wanna go ahead and add a record, you can do that through the CloudKit console.

we talked about records. another important piece of that are what's called databases. so the way the hierarchy works is you've got a container. So typically, one app will have one container. You have two environments, for production or development, and then you have two databases, private and public, and then you can set up zones, and then each zone will have, its group of different records.

So with the databases, there's a private database and a public database. So each user has their own private database that is just set up for them when they log in. [00:03:00] And then there's the public database, which has records shared, for the entire app, so every user has access to those. here's a example of your typical SwiftUI app using macOS, using CloudKit, and you can see all the record information in here.

so today we'll be talking specifically about what is CloudKit Web Services. Why would you ever wanna do anything server side with CloudKit?

How does server-side CloudKit work? We'll be talking about the process I went through for coding CloudKit web services, converting the documentation to a different documentation format, and then some of the challenges that came with building the library I'll be talking about today, and what's next [00:04:00] So what is CloudKit Web Services?

So if you have CloudKit, it's typically a framework you're to import into your Xcode project But CloudKit Web Services basically allows you to have access to CloudKit via the web. there's two ways of doing this. the easiest way is if you're just talking about a webpage, there's CloudKit JS.

You would just import that into your JavaScript, TypeScript, whatever, and from there you can go ahead and access an API that gives you more or less what you'd get with the CloudKit framework in Swift. And then what we'll be talking about today is the, web service requests. So you can actually, there's a REST API for doing a lot of the stuff that you can do with, the CloudKit framework and CloudKit JS[00:05:00] 

So why would anybody want to use CloudKit Web Services? And I'm not talking about CloudKit JS, but the web service requests. We talked earlier about the private and public database, and I think each of these have their own use case for why you'd want to do this. let's talk about why you'd ever want to do something with a private database on the web.

And I wanna talk about my app that I built several years ago called HeartTwitch. This was before Sign in with Apple, before, quite a few features. And it's a Apple Watch app, and the way it works is you would post your heart rate to a server backend, a Vapor one, and then the web browser would open a WebSocket and listen for the heart rate, and then the server would continually feed the web browser [00:06:00] your heart rate during your workout.

And then you could take that, and you could either point OBS or some sort of streaming software to the URL or the web browser, and then they can go ahead and stream, like an overlay to showing their heart rate while they're streaming So like I said, this was before Sign in with Apple, and the website has a username and password interface, but I didn't wanna have to use username and password for the Apple Watch.

So I decided what I'd do is use CloudKit on the watch. Since it's automatic more or less, you'll already be signed into CloudKit. And what you would do then is on the web browser, after you've signed into your Apple Watch, you can sign into CloudKit using CloudKit JS interface, and that will pull up every Apple Watch that you have, signed up for with that [00:07:00] account.

And then we'll add that to the PostgreSQL database. And it's used basically now as another form of authentication. And then that means that when you post that heart rate, it'll know which user account is mapped to that, and then where to stream that to through the WebSocket. Lately, though, I've been more interested in uses with the public database.

I don't know if you're familiar with, my app Bushel, but it's basically a virtual machine app for macOS or any developer, who needs an Apple platform. And the idea let's say you wanted to, test something out on an old version of macOS, like Monterey or Sonoma. You could then get the image, what's called a restore image, to install that, particular version of macOS on a VM.

one of the things I needed was a way to keep track of all the different restore images and their URLs. So what I ended [00:08:00] up doing was setting up a cron job essentially in, GitHub Actions that could then pull the data from the web as far as what images are, and the different versions of Xcode and Swift that they support.

And then I would take that, and I would throw that into a public database, and then now Bushel just needs access to that CloudKit container and can then pull up a list of different Restore images and any metadata attached to it. And so what I ended up building was a Swift package called MiscKit, 

This is a web interface that I built to test it out with the help, of course, certain other tools which we'll get to. And you can test it out either using CloudKit JS or you can test it out through, a simple Hummingbird server underneath that, uses [00:09:00] MiscKit, to then send different calls

So let's talk about how I was gonna do this using CloudKit Web Services. like I said, here's the CloudKit Web Services page, and we can see here this wonderful document revision history. yeah, that hasn't been updated in quite a while. CloudKit hasn't been updated in quite a while as far as the back end is concerned.

this was a long time ago, more than ten years ago. And just looking at some of these APIs, there's a lot of documentation about how it works and what's going on. So you can tell I was a little bit frustrated. it was gonna take a while for me to implement everything. there's all sorts of challenges like writing each API by hand, verifying if the documentation is even correct.

I had to learn each piece of CloudKit architecture and how it worked. I had to implement encryption for [00:10:00] server-server authentication, and I'd have to also write my own code for supporting both server-side calls using SwiftNIO or client-side calls using, URLSession

So there are a few things that really helped me out over the last few years to make this even more possible and easier to do

So one of them was a Swift package that came out a few years ago, and was revealed at WWDC back in twenty twenty-three, and I'm talking about the Swift OpenAPI generator. And what it lets me do is it will let me create an OpenAPI document based on CloudKit web services documentation and turn that into Swift code.

So the way the OpenAPI generator [00:11:00] works, probably should explain how OpenAPI works, but it's a YAML-based, markdown like, specification, and it typically has three or four components. you have at the top

So the OpenAPI, spec has, a lot of components to it, but I think main piece you're gonna wanna know about is you have to look at metadata at the [00:12:00] top

So you have the metadata at the top. You have your server URLs, different paths, whether they're post or get or put, the different responses, which you could either put the schema right in there or you can use, components to specify the entire schema, of how the data is structured

So the API generator can then allow you to create a generated client, and it already has code and implementation for URLSession or, SwiftNIO. So it's automatically we have what we need for [00:13:00] accessing it through a client. and then, there's different libraries available for, different, server types.

So we have also our server for different, client transports as well So the challenge for me was then, like

How is it gonna take all this web services documentation and turn it into an OpenAPI document? And so that's when another thing came out a couple of years ago that was gonna help me with this. And of course, I'm talking about AI[00:14:00] 

Yeah, I then would create the OpenAPI document, and I have-- This is basically what it looks like. So a lot of metadata here, and then You can see all the different pieces and paths and components it would end up creating for me to do this

So then basically what I had is a workflow where I would go through each of the different Rust calls documented on CloudKit web services and have the AI convert that. We'd, and then would also create abstractions and as well, to do this

obviously there were some challenges. this was started a couple of years ago, so wasn't [00:15:00] as advanced as it is today. So we had issues with hallucinations and context window issues, as well as just sometimes it would overdo stuff. It would build all sorts of scaffolding, like retries and things like that, that just were more than what I needed for what I was trying to implement I was pretty good at writing unit tests, but one of the issues I ran into was, it would say it did something, but then when you actually would try to run something, it wouldn't work.

So part of the process was also creating, a separate demo Swift package called Miss Demo, and I added, a command line tool that will then, build integration tests and also it would build that web interface that I'd shown earlier that would allow me to go ahead and test each API as was [00:16:00] implemented within the web interface

That was important, and there was really three big challenges I had to get over to get the Swift code working the way I wanted to. the first of those is implementing the different authentication methods. when you use an app, obviously it'll just work right out of the box. There isn't anything you need to do because most users are already signed into their iCloud account, just I show you here with my iPhone So to do, the authentication methods, you'd go to your container and then go to Token & Keys.

And here you could set up either your API token or your server-to-server key. the API token, that's pretty easy to do. You just go in, click the plus sign at the top, give it a name, specify your sign-in callback, which we'll explain in a little bit, and then whether you want [00:17:00] certain domains, you want it restricted to certain domains, and if you want to have user discoverability at sign-in as well 

For each web service call, you just need to add the query item for the API token

And then there's of course, the way to do it using the CloudKit JS. You just put in the content identifier and the API token and which environment you wanna use. And then from there, you'd have API token access, which really isn't much besides just the public database.

What you really want most of the time is the web authentication token, and that requires a user to sign [00:18:00] in

so depending on which one, you would use the CK API token

And then you would have to attach the WebAuth token. The way it works is you'd have a Sign in with Apple button somewhere in your interface, which would then open a browser window. And then from there, you would have the user sign in. Once they're signed in, depending on the sign-in method used, whether it's a post message, you would attach, an event listener to your window, and then you could grab the WebAuth token from there.

Or you could just grab the WebAuth token from wherever your callback URL [00:19:00] is

sometimes it would use CK Session instead of CK Web Auth Token. So that's just something I had to, keep in mind with the code, is that sometimes it would change different names. It would either be CK Session or CK Web Auth Token

there's a way not only to grab the WebAuth token from JavaScript, but you can actually, get it through, the CloudKit framework on iOS. you just supply, the API token to a fetchWebAuthToken operation and then run that operation and you'll have access to, the result which will give you the WebAuth token for user.

So then from there you can save that to like a database or something like that, so that way they have access to it. you have access to it if you have a web interface or some sort of a server end operation you need to do Here's a refactor that [00:20:00] uses that same operation and, I turned it into a regular async await call here So we know how to do the API token.

we know how to do a WebAuth token using URL queries or query items. Let's now talk about server to server. So luckily, they provide instructions to get started with that

Go into the tokens and keys section. Go ahead and create a new server-to-server key And it gives you instructions on how to the private key. here's an example. We just create the, private key, and then we can grab the public key. if you want to, you can just use pub-pasteboard copy to grab it as well.[00:21:00] 

And then you just paste the public key in step three here And now you have a server-to-server, authentication set up

There are some differences between the access you get based on the different authentication methods

So with the API key, you have access to anything that's public in the public database. With the web authentication token, you have access to, the private database and the shared database

And then with the public database, you have access to whatever that particular record has given rights to. And then with server-to-server[00:22:00] 

server to server, you have access to, whatever that particular user has access to when you created the server-to-server key. So we talked about the OpenAPI generator. There's also the ability to add middleware. there's the idea of server middleware, which is where you can modify the request before it's received by whatever implementation, you have set up.

Or in our case, we're gonna be using the client middleware to, interrupt before a HTTP request is sent and modify that. So there's documentation on [00:23:00] client middleware. There's even a great example of how to set up authentication middleware using a bearer token. 

If you have a bearer token, here's how you can add the token to the authorization header field And since we have different authentication methods available, We need a way to abstract that and then have each different authentication method, implemented differently.

So here we have what's called, a token manager, and then the token manager has access to the authenticator. And then from there, the authenticator will go ahead and modify the request in the body, of the HTTP request So here's a diagram to show you how that works. Again, we have the call coming in or the call coming out, and we have the OpenAPI client, which then calls our authentication middleware, which checks with the token [00:24:00] manager to see if there's an authenticator.

And then from there, we take the authenticator, it modifies the request in the body, and then it goes ahead and sends that. The OpenAPI client will then go ahead and send that to, CloudKit

the API token, obviously that's the easiest part because typically you'll have that and it doesn't get modified, so you just need to add the URL query item to the request. With the web authentication token, we just need to encode the web authentication token, and basically that means replacing plus and slash and equals for the URL, and then we add those query items as well

and server to server, we need, a way to encrypt stuff and send that. 

We have the private key, so we just need that. [00:25:00] And then we need to take that private key and create a request signature, and that takes the key ID, the private key, the request body, and the sewer service URLs, and then it does some magic to calculate what's needed for the different headers and sends those header, attaches those headers to the HTTP request.

So here's our WebAuth token modification. This is what it looks like for server to server. So we just grab the body data from the request. We create that request signature. The request signature then, calculates the hash of the body which that's what this code is here Using 256, SHA-256

And then we go to the other, initializer, which then gives us what's called the payload. [00:26:00] And the payload just needs the ISO date string, the body hash, and the web server subpath. So basically that's the URL of our REST call from the domain to the end of the path[00:27:00] [00:28:00] 

So now we have the components we need for the request signature, and then we could, go ahead and update the HTTP fields for the three different fields that we need. [00:29:00] Now let's talk about field type polymorphism. So if any of you have done any work with JSON that's more JavaScript-based, and supports different field types that you're not totally aware of, you kinda run into the same thing here because there's a lot of different types that we support in CloudKit Like we said earlier, I have the list here.

I created my own, structure for location reference asset, specifically location, 'cause I didn't wanna have to depend on core location on the server And created an enum for each of these types the reference just contains the record name for the reference and the different action type

And the asset crate contains the information from the asset, which then gives you the download URL you can use[00:30:00] 

This is how the field value is used in a request. You can see here in the OpenAPI, we use the one of, and we have enum type that's optional for if it's a list

Next, we have error handling. So luckily, CloudKit web services gives us all the HTTP status codes that are available. this is what the JSON would look like from an error. And so then here's what the OpenAPI looks like. We set up an enum for the error codes and strings for everything else. And this is what we end up having from the generated code[00:31:00] 

The problem comes when you get a five hundred error. So there was one call that was documented that probably they removed the implementation for, and that's reco-res-discover all user identities. This is the one thing that was, documented but is no longer available to us. I think they removed the stuff for privacy reasons a few years ago.

but you can see here, I, submitted, Apple feedback for this. So how are we gonna deploy and use something like this? So in my case, I mentioned that I use GitHub and setting up a schedule using GitHub actions. You can paste in the key ID and the API token and the WebAuth token as a repository secret.

You can either do a private key or the base sixty-four encoded version. And then here's where you [00:32:00] have set up the cron job and its schedule. And then I end up refactoring this into a separate action and passing in the different, like the environment, the container ID, and the private key, and the key ID 'cause I'm using server-to-server authentication

And then here is the refactored action. we downloaded the prebuilt binary for our Swift command line tool, and then we go ahead and run, 

If we don't have the Swift command line tool, we will just go ahead and build it and save it as an artifact

Make the binary executable, and then I go ahead and run my command line tool with all the information that's needed in the environment variables. So you can see here's an example. This is just a demo interface for Bushel for being [00:33:00] able to list out all of the restore images that are available and the different, values about whether they're signed or not, or they're pre-release

