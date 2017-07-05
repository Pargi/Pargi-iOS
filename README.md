![Icon](/Images/Icon.png)

# Pargi

Pargi is your assistant for mobile parking in Estonia, helping you determine the parking zone and making sure you don't forget to end the meter once your done.

## Contents

The contents of this repository include all of Pargi's iOS code, it is written 100% in Swift (with a few additional 3rd party libraries). There are a few elements that are not part of the repository for security measures, for example the API key for communicating with the backend service that gathers stats on the usage of the app.

Irregardless, cloning and building this repo should produce a working copy of the application, with a few caveats that come with iOS applications (for example, you would need to change the bundle identifier to generate a new valid provisioning profile)

## Motivation

You can read further about the motivation behind rebuilding and open sourcing this project on [Medium](https://medium.com/@henrinormak/pargi-goes-oss-64ee1eeab403)

## Building

Building this project will require [Carthage](https://github.com/Carthage/Carthage). Once checked out, run `carthage bootstrap` in the top level directory to get all the necessary dependencies. After that the main Xcode project should build as expected (fingers crossed, no provisioning hell).

## Contributing

Issues and Pull Requests to the project are more than welcome. The database that Pargi uses for its parking zones is located at a [separate repository](https://github.com/Pargi/Data), all suggestions regarding the database should go there.

Main focus on external contributions should be on making the code better, in terms of readability and good practices. As the intent of the project is to provide a fully-fledged application to learn from, it makes sense to keep the list of features limited, however, feature requests are welcome as well. For ideas, have a look at the feature list above.

## License

```
MIT License

Copyright (c) 2017 Henri Normak

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
