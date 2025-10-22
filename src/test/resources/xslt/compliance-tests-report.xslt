<xsl:stylesheet
        xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
        xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
        xmlns:map   = "http://www.w3.org/2005/xpath-functions/map"
        xmlns:err   = "http://www.w3.org/2005/xqt-errors"

        xmlns:ajp   = "http://xmljacquard.org/ajp"
        xmlns:tests = "local:functions:for:test"

        expand-text = "yes"
        exclude-result-prefixes = "#all"

        version="3.0" >

    <xsl:use-package name="http://xmljacquard.org/ajp" package-version="*"/>

    <xsl:include href="tests-common.xslt" />

    <xsl:param name="ctsTestsURI" as="xs:string" />
    <xsl:param name="ajpTestsURI" as="xs:string" />
    <xsl:param name="reportURL"   as="xs:string" />

    <xsl:variable name="tests" as="map(xs:string, map(*))" >
        <xsl:map>
            <xsl:map-entry key="'cts'" select="json-doc($ctsTestsURI)" />
            <xsl:map-entry key="'ajp'" select="json-doc($ajpTestsURI)" />
        </xsl:map>
    </xsl:variable>

    <xsl:template name="xsl:initial-template" >

        <xsl:variable name="results" as="element(result)*" select="tests:results()" />
        <xsl:variable name="numberOfFails" as="xs:integer"
                      select="count($results[passed eq 'false'])" />

        <xsl:result-document href="{$reportURL}" method="xhtml" indent="yes" >
            <html>
                <xsl:sequence select="tests:reportHead()" />
                <body>
                    <h1>Results of the Compliance Test Suite and Other Tests</h1>
                    <table class="summary centered">
                        <thead>
                            <tr>
                                <th>Origin</th>
                                <th>Number of Tests</th>
                                <th>Number of Tests Passed</th>
                                <th>Number of Tests Failed</th>
                            </tr>
                        </thead>
                        <tbody>
                            <xsl:for-each-group select="$results" group-by="origin" >
                                <tr>
                                    <td>{current-grouping-key()}</td>
                                    <td>{count(current-group())}</td>
                                    <td>{count(current-group()[passed eq 'true' ])}</td>
                                    <td>{count(current-group()[passed eq 'false'])}</td>
                                </tr>
                            </xsl:for-each-group>
                        </tbody>
                        <tfoot class="summary normal-parse-error">
                            <tr>
                                <td>Total</td>
                                <td>{count($results)}</td>
                                <td>{count($results[passed eq 'true' ])}</td>
                                <td>{count($results[passed eq 'false'])}</td>
                            </tr>
                        </tfoot>
                    </table>

                    <xsl:variable name="statusText" as="xs:string"
                                  select="if ($numberOfFails eq 0) then 'All Passed'
                                                                   else $numberOfFails || ' Tests Failed'" />
                    <xsl:variable name="statusColorClass" as="xs:string"
                                  select="if ($numberOfFails eq 0) then 'status-green'
                                                                   else 'status-red'" />
                    <h2>Status of the test: <span class="{ $statusColorClass }">{ $statusText }</span></h2>
                    <div class="table-container" >
                        <table class="tests">
                            <xsl:sequence select="tests:tableHead()" />
                            <tbody>
                                <xsl:for-each select="$results" >
                                    <tr class="{tests:trClass(.)}">
                                        <td class="centered col-0">{./number}</td>
                                        <td class="centered col-1">{./origin}</td>
                                        <td class="col-2">{./name}</td>
                                        <td class="centered col-3 {tests:passedClass(.)}">{
                                            tests:checkXMarkOrValue(./passed)
                                        }</td>
                                        <td class="centered col-4 {tests:parsedClass(.)}">{
                                            tests:checkXMarkOrValue(./parsable)
                                        }</td>
                                        <td class="col-5">{./query}</td>
                                        <xsl:if test="./outputValues" >
                                            <td class="col-6">{./queryArg}</td>
                                            <td class="col-7">{./outputValues}</td>
                                            <td class="col-8">{./outputPaths}</td>
                                        </xsl:if>
                                        <xsl:if test="./parseError" >
                                            <td class="col-6" colspan="3">{./parseError}</td>
                                        </xsl:if>
                                    </tr>
                                </xsl:for-each>
                            </tbody>
                        </table>
                    </div>
                </body>
            </html>
        </xsl:result-document>

        <xsl:sequence select="$numberOfFails" />

    </xsl:template>

    <xsl:function name="tests:checkXMarkOrValue" as="item()?" >
        <xsl:param name="item" as="item()?" />

        <xsl:sequence select="if ($item = ('true', 'false'))
                              then ( $CHECK_MARK_UNICODE[$item eq 'true'], $X_MARK_UNICODE )[1]
                              else $item" />
    </xsl:function>

    <xsl:function name="tests:trClass" as="xs:string" >
        <xsl:param name="result" as="element(result)" />

        <xsl:sequence select="if ($result/passed eq 'true' and $result/parsable eq 'true')
                              then 'executing'
                              else if ($result/passed eq 'true' and $result/parsable eq 'false')
                              then 'normal-parse-error'
                              else 'real-error'" />
    </xsl:function>

    <xsl:function name="tests:passedClass" as="xs:string" >
        <xsl:param name="result" as="element(result)" />

        <xsl:sequence select="if ($result/passed eq 'true')
                              then 'passed'
                              else 'real-error'" />
    </xsl:function>

    <xsl:function name="tests:parsedClass" as="xs:string" >
        <xsl:param name="result" as="element(result)" />

        <xsl:sequence select="if ($result/passed eq 'true' and $result/parsable eq 'true')
                              then 'parses'
                              else if ($result/passed eq 'true' and $result/parsable eq 'false'
                                       and $result/parseError)
                              then 'parse-error'
                              else 'real-error'" />
    </xsl:function>

    <xsl:function name="tests:reportHead" as="element(head)" >
        <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title>Results of the Compliance Test Suite and Other Tests</title>
            <style>{'
                h1     { color: red; }
                .tests { width: 100%;
                         border: 1px solid rgb(140 140 140);
                         border-collapse: collapse;
                         table-layout: fixed;
                       }
                th,
                td     { border: 1px solid rgb(160 160 160);
                         border-collapse: collapse;
                         overflow: visible;
                         overflow-wrap: break-word;
                       }

                .testshead
                       { background-color: #f2f2f2;  /* Background color for header */
                         position: sticky;           /* Make the header sticky */
                         top: 0;                     /* Position it at the top of the container */
                         z-index: 10;                /* Ensure it stays above other content */
                       }

                .centered { text-align: center; }
                .executing          { background-color: white;  }
                .normal-parse-error { background-color: rgb(211 211 211);
                                      font-style: italic
                                    }
                .real-error         { background-color: red;    }
                .status-red         { background-color: red;    }
                .status-green       { background-color: green;    }

                .table-container {
                                     max-height:  800px;      /* Set the height of the container */
                                     overflow-y: auto;        /* Enable vertical scrolling */
                                     border: 1px solid #ccc;  /* Optional border */
                                 }
                .passed { color: green; }
                .parses { color: green; }
                .parse-error { color: orange; }
                .col-0 { width:  2%; }
                .col-1 { width:  4%; }
                .col-2 { width: 22%; }
                .col-3 { width:  3%; }
                .col-4 { width:  3%; }
                .col-5 { width: 19%; }
                .col-6 { width: 19%; }
                .col-7 { width: 14%; }
                .col-8 { width: 14%; }

                .summary  { border: 1px solid rgb(140 140 140);
                            table-layout: auto;
                          }
            '}</style>
        </head>
    </xsl:function>

    <xsl:function name="tests:tableHead" as="element(thead)" >
        <thead class="testshead">
            <tr class="centered testshead">
                <th class="centered col-0 testshead">#</th>
                <th class="centered col-1 testshead">Origin</th>
                <th class="centered col-2 testshead">Test Name</th>
                <th class="centered col-3 testshead">Passed</th>
                <th class="centered col-4 testshead">Parses</th>
                <th class="centered col-5 testshead">Query</th>
                <th class="centered col-6 testshead">QueryArg</th>
                <th class="centered col-7 testshead">Output Values</th>
                <th class="centered col-8 testshead">Output Paths</th>
            </tr>
        </thead>
    </xsl:function>

    <xsl:function name="tests:results" as="element(result)*">

        <xsl:for-each select="map:keys($tests)" >

            <xsl:variable name="origin" as="xs:string" select="." />

            <xsl:for-each select="$tests($origin)?tests?*" >

                <xsl:variable name="test" as="map(*)" select="." />

                <xsl:variable name="getSegmentsMap" as="map(*)" >
                    <xsl:map>
                        <xsl:try>
                            <xsl:map-entry key="'segments'" select="ajp:getSegments($test?selector)" />
                            <xsl:catch>
                                <xsl:map-entry key="'error'"
                                               select="ajp:errorSummary($err:code, $err:description)" />
                            </xsl:catch>
                        </xsl:try>
                    </xsl:map>
                </xsl:variable>

                <xsl:variable name="output" as="map(xs:string, item()?)*"
                              select="if (map:contains($getSegmentsMap, 'segments'))
                                      then ajp:applySegments($test?document, $getSegmentsMap?segments)
                                      else ()
                                     " />

                <result>
                        <number>{       position()                                          }</number>
                        <origin>{       $origin                                             }</origin>
                        <name>{         $test?name                                          }</name>
                        <passed>{       tests:passed($test, $getSegmentsMap, $output)       }</passed>
                        <parsable>{     map:get($test, 'invalid_selector') => boolean()
                                                                           => not()         }</parsable>
                        <query>{        $test?selector
                                              => ajp:replaceHigherPlaneChars()
                                              => ajp:escape()                               }</query>
                        <queryArg>{     tests:prettyPrintJson( $test?document )
                                              => ajp:replaceHigherPlaneChars()
                                              => ajp:escape()                               }</queryArg>
                    <xsl:if test="map:contains($getSegmentsMap, 'segments')" >
                        <outputValues>{ tests:prettyPrintJson( ajp:arrayOfValues($output) )
                                              => ajp:replaceHigherPlaneChars()
                                              => ajp:escape()                               }</outputValues>
                        <outputPaths>{  tests:prettyPrintJson( ajp:arrayOfPaths ($output) ) }</outputPaths>
                    </xsl:if>
                    <xsl:if test="map:contains($getSegmentsMap, 'error')" >
                        <parseError>{   $getSegmentsMap?error                               }</parseError>
                    </xsl:if>
                </result>
            </xsl:for-each>
        </xsl:for-each>

    </xsl:function>

    <xsl:function name="tests:passed" as="xs:boolean" >
        <xsl:param name="test"           as="map(*)"                   />
        <xsl:param name="getSegmentsMap" as="map(*)"                   />
        <xsl:param name="output"         as="map(xs:string, item()?)*" />

        <xsl:sequence select="if (map:contains($getSegmentsMap, 'error'))
                              then (map:contains($test, 'invalid_selector')
                                     and
                                    $test?invalid_selector)
                              else if (map:contains($test, 'invalid_selector')
                                       and
                                       $test?invalid_selector)
                              then false()
                              else (
                                  tests:compareValues($test, $output)
                                   and
                                  tests:comparePaths($test, $output)
                              )
                             " />
    </xsl:function>


    <xsl:function name="tests:compareValues" as="xs:boolean" >
        <xsl:param name="test"   as="map(*)"                   />
        <xsl:param name="output" as="map(xs:string, item()?)*" />

        <xsl:sequence select="let $values := ajp:arrayOfValues($output)
                              return if (map:contains($test, 'result'))
                                     then deep-equal($test?result, $values)
                                     else
                                        some $altTestResult in $test?results?*
                                        satisfies deep-equal($altTestResult, $values)
                             " />
    </xsl:function>

    <xsl:function name="tests:comparePaths" as="xs:boolean" >
        <xsl:param name="test"   as="map(*)"                   />
        <xsl:param name="output" as="map(xs:string, item()?)*" />

        <xsl:sequence select="let $paths := ajp:arrayOfPaths($output)
                              return if (map:contains($test, 'result_paths'))
                                     then deep-equal($test?result_paths, $paths)
                                     else
                                        some $altTestPaths in $test?results_paths?*
                                        satisfies deep-equal($altTestPaths, $paths)
                             " />
    </xsl:function>

</xsl:stylesheet>
