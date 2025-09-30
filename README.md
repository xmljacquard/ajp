# ajp -- A JSONPATH Processor -- implements RFC9535 using XSLT and ixml #

## Introduction ##

In this implementation of RFC9535 in XSLT/XPath, 
an output `node` (from RFC 1.1 Terminology) is modeled as a singleton map
where the singleton map's key is the string Normalized Path location 
of the node and the map's value is the associated JSON value at that location.

The `nodelist` is hence the XDM sequence of singleton maps, or `node`s. 

## Warning on Submodules ##

Because this repo includes two submodules in order to recover the compliance test suite
and the comparison test suite, there are some extra operations that are necessary to recover 
this repo from github.com.

There are at least two different options:

1. When cloning the project initially, use the option:  `git clone --recurse-submodules`.
2. If the project has already been cloned, retrieve the submodules with: `git checkout --recurse-submodules main`.

I apologize for the inconvenience: a `git submodule` is by nature a horrible thing.

## RFC9535 Compliance ##

The java unit tests generate two reports that give information about 
compliance with JSONPATH/RFC9535.

The first report, 
[ajp-compliance-tests-report.html](ajp-compliance-tests-report.html), 
shows the output of the Jsonpath Compliance Test Suite (cts) tests 
and compares them to the expected output. This report shows all 
tests results as compliant, producing either identical output to the 
test suite's or producing a query compilation error for tests with
`invalid_selector: true` set.

The second report, [ajp-consensus-report.html](ajp-consensus-report.html),
shows the output of `ajp` compared against the consensus. It is important to note
that some consensus outputs are not RFC9535 compliant, hence there are
three tests with differences. Furthermore, for many of the comparison tests,
no consensus was found among the 50 or so JSONPATH implementations. `ajp` 
is not currently listed in the [comparison project](https://github.com/cburgmer/json-path-comparison). 

## Usage ##

Whereas, in principle, the implementation should work in any XSLT3.0 processor 
where an `ixml` extension is available, the current implementation is based 
upon the `nineml` processor `coffee-sacks` ( https://github.com/nineml/nineml )
and the Saxonica XSLT processor ( https://github.com/Saxonica/Saxon-HE ).

To run `ajp` from XSLT, the following Saxonica processor configuration is required:

1. Set the XML version to be 1.1 so that the XSLT processor can handle a larger
range of unicode characters
2. Register the CoffeeSacks extension functions for `ixml`
3. When creating the XSLT compiler for the stylesheet using `ajp`, perform
a `compilePackage()` on `ajp.xslt` and add the resultant `XsltPackage`
to the compiler using `importPackage()`. This makes the package available for usage.

The above three steps are demonstrated in the `XsltXpathEnvironment` class.

### Usage from XSLT ###

The `ajp` package top-level module, `ajp.xslt`, lists the functions and variables
that are made available to users of the package (i.e. with `visibility="public"`).

In order to use the package, an XSLT stylesheet must declare its usage:

```xml
    <xsl:use-package name="http://xmljacquard.org/ajp" package-version="*"/>
```
and also the package namespace, with `ajp` suggested as a standard prefix.

```
    xmlns:ajp = "http://xmljacquard.org/ajp"
```

The XSLT test modules `compliance-tests-report.xslt` 
and `consensus-queries-report.xslt`
are  examples of usages of `ajp` from XSLT. The test classes
`RunComplianceTestsInXslt` and `RunConsensusQueriesInXslt` execute the
respective test stylesheets from java.

#### Available `ajp` XPath Functions ####

- `function ajp:getSegments($jsonpathQuery as xs:string) as map( xs:string, array(function(*))* )*` 

`ajp:getSegments()` takes a JSONPATH query string argument and returns a sequence of "segments" that 
correspond to the query. The "segments" are compiled from the Abstract Syntax Tree (AST) returned 
by `ixml` (Invisible XML).

- `function ajp:applySegments($root as item()?, $segments as map( xs:string, array(function(*))* )*) as map(xs:string, item()?)* `

This function takes the segments returned by `ajp:getSegments()` and the query argument json value and 
returns the `nodelist` that corresponds to the processing of the query on the query argument.

Those are the two functions necessary for jsonpath processing.  Some other functions are available.

- `function ajp:getAST($jsonpathQuery as xs:string) as document-node(element(jsonpath-query))`

It's possible to retrieve the XML version of the AST via the function `ajp:getAST()`.
The AST is returned as a document node with root element `jsonpath-query`.
This can be useful for debugging but is not required for processing as `ajp:getSegments()` performs this.

- `functiopn ajp:arrayOfValues($nodelist as map(xs:string, item()?)*) as array(item()?)`
- `functiopn ajp:arrayOfPaths($nodelist as map(xs:string, item()?)*) as array(xs:string)`

These two functions take the output `nodelist` from `ajp:applySegments` and return an array of either 
the "values" or the "locations" from the nodes in the `nodelist`.

- `function ajp:errorSummary($error_code as xs:QName, $error_description as xs:string) as xs:string`

In case of a query grammar error, the XSLT environment will throw an exception that can be caught in in an
`<xsl:catch>` statement. `ajp:errorSummary()` takes as arguments the values `$err:code` and `$err:description` 
available within the `<xsl:catch>` element and produces a string error message.

### Usage from Java ###

In addition to the XSLT package, this repo provides some simple Java classes that demonstrate how to call
into the `ajp-runner` XSLT environment from Java. 
Some examples in the form of unit tests are available in the test class `AjpRunnerTests`

The Java methods are available in the `AjpRunner` class.

#### AjpRunner methods ####

- `AjpRunner.withQuery()`

A jsonpath query can be compiled using the `AjpRunner.withQuery()` method, passing as sole argument the 
string for the jsonpath query.  This method can throw an exception: `IllegalStateException` if a query has already 
been compiled for this instance of `AjpRunner` or a `SaxonApiException` in case there is a grammar or type 
problem with the query itself.

- `AjpRunner.getNodelist()`

Two overloaded methods are available for `getNodelist()` which can only be called after `withQuery()` has been called
with a successful return. Multiple calls to `getNodelist()` can be made with the same `AjpRunner` instance, which
can save some processing time if a same jsonpath query is used on multiple JSON query arguments.

One of the methods accepts the `XdmValue` argument that corresponds to the JSON query argument. In addition, for 
facility, there is a method that takes a `String` argument which represents a JSON query argument, for which
the `String` is then converted to an `XdmValue`.

Other than usage errors such as not calling `withQuery()` before `getNodelist()`
or passing an erroneous JSON string value,
no Exceptions should occur from the call to `getNodelist()`.

The return from `getNodelist()` is a `XdmValue` that corresponds to a sequence of singleton maps, each map having the
location (normalized jsonpath) as the key and the `XdmValue` of the value that was selected.  These values can be 
retrieved from the `XdmValue` by different means.

- `AjpRunner.getArrayOfValues()`
- `AjpRunner.getArrayOfPaths()`
- `AjpRunner.getArrayOfNodes()`

The `XdmValue` return from `getNodelist()` can be passed to `getArrayOfValues()` 
and `getArrayOfPaths()` to retrieve a JSON array of 
only the values or locations (normalized paths) retrieved by the query. This is useful 
for comparing against the test suites which show the
expected outcomes as an array of values or an array of localizations (normalized paths).

In addition, the method `getArrayOfNodes()` returns a JSON array of JSON objects, each object being a `node`
where the key is the location and the value is the JSON value at that location.

- `AjpRunner.serializeToJson()`

The `XdmValue` returns from the methods `getArrayOfValues()`, `getArrayOfPaths()` and `getArrofOfNodes()`
can be passed to the method `serializeToJson()` in order to
create a string output with the JSON values.  However, please note that the `XdmValue` 
return from `getNodelist()` is not
itself JSON as it is a sequence of maps; sequences are not allowed in JSON.  

- `AjpRunner.errorSummary()`

For the case where the `withQuery()` method returns a `SaxonApiException`, there is a utility method
`errorSummary()`
that generates a `String` from that exception that gives a good summary of problem encountered
in the query parsing.