<xsl:stylesheet
        xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
        xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
        xmlns:map   = "http://www.w3.org/2005/xpath-functions/map"
        xmlns:array = "http://www.w3.org/2005/xpath-functions/array"
        xmlns:err   = "http://www.w3.org/2005/xqt-errors"

        xmlns:ajp   = "http://xmljacquard.org/ajp"
        xmlns:tests = "local:functions:for:test"

        expand-text = "yes"
        exclude-result-prefixes = "#all"

        version="3.0" >

    <xsl:use-package name="http://xmljacquard.org/ajp" package-version="*"/>

    <xsl:include href="consensus-html-extraction.xslt" />
    <xsl:include href="tests-common.xslt"              />

    <xsl:param name="queriesURI" as="xs:string" />
    <xsl:param name="reportURL"  as="xs:string" />

    <xsl:variable name="selectorFiles" as="xs:anyURI*"
                  select="uri-collection($queriesURI || '?recurse=yes;select=selector')" />

    <xsl:variable name="consensuses" as="element(consensuses)" >
        <xsl:call-template name="consensuses" />
    </xsl:variable>

    <xsl:template name="xsl:initial-template" >

        <xsl:variable name="results" as="element(result)*" select="tests:results()" />

        <xsl:result-document href="{$reportURL}" method="xhtml" indent="yes" >
            <html>
                <xsl:sequence select="tests:reportHead()" />
                <body>
                    <h1>Results of the Consensus Test Suite</h1>
                    <h2>Summary Results</h2>
                    <table class="summary centered">
                        <thead>
                            <tr>
                                <th>Result Category</th>
                                <th>Number of Tests in Category</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr class="centered consensusGreen">
                                <td>Results Match Consensus Values in Order</td>
                                <td>{count($results[tests:consensusClass(.) eq 'consensusGreen'])}</td>
                            </tr>
                            <tr class="centered consensusYellow">
                                <td>Results Match Consensus Values in a Different Order</td>
                                <td>{count($results[tests:consensusClass(.) eq 'consensusYellow'])}</td>
                            </tr>
                            <tr class="centered consensusRed">
                                <td>Results with a different value from the Consensus</td>
                                <td>{count($results[tests:consensusClass(.) eq 'consensusRed'])}</td>
                            </tr>
                            <tr class="centered consensusOrange">
                                <td>Tests for which there is No Consensus</td>
                                <td>{count($results[tests:consensusClass(.) eq 'consensusOrange'])}</td>
                            </tr>
                        </tbody>
                        <tfoot class="summary normal-parse-error">
                            <tr class="centered">
                                <td>Total</td>
                                <td>{count($results)}</td>
                            </tr>
                        </tfoot>
                    </table>
                    <h3><em>N.B. For the <span class="consensusRed">{count($results[tests:consensusClass(.) eq 'consensusRed'])} results
                        that are different</span>, the consensus results are not conformant with RFC9535</em></h3>
                    <h2>Detailed Results</h2>
                    <div class="table-container" >
                        <table class="tests">
                            <xsl:sequence select="tests:tableHead()" />
                            <tbody>
                                <xsl:for-each select="$results" >
                                    <tr class="{tests:trClass(.)}">
                                        <td class="centered col-0">{./number }</td>
                                        <td class="col-1">{         ./name   }</td>
                                        <td class="centered col-2 {tests:parsedClass(.)} ">{
                                            tests:checkXMarkOrValue(.)
                                        }</td>
                                        <td class="col-3">{./query}</td>
                                        <xsl:if test="./outputValues" >
                                            <td class="col-4">{./queryArg}</td>
                                            <td class="col-5">{./outputValues}</td>
                                            <td class="col-6">{./outputPaths}</td>
                                        </xsl:if>
                                        <xsl:if test="./parseError" >
                                            <td class="col-4" colspan="3">{./parseError}</td>
                                        </xsl:if>
                                        <td class="col-7 {tests:consensusClass(.)}">{
                                            tests:consensusText(.)
                                        }</td>
                                    </tr>
                                </xsl:for-each>
                            </tbody>
                        </table>
                    </div>
                </body>
            </html>
        </xsl:result-document>

        <xsl:sequence select="0" />

    </xsl:template>

    <xsl:function name="tests:checkXMarkOrValue" as="item()?" >
        <xsl:param name="result" as="element(result)" />

        <xsl:sequence select="( $CHECK_MARK_UNICODE[$result/parsed eq 'true'], $X_MARK_UNICODE )[1]" />
    </xsl:function>

    <xsl:function name="tests:trClass" as="xs:string" >
        <xsl:param name="result" as="element(result)" />

        <xsl:sequence select="if ($result/parsed eq 'true')
                              then 'executing'
                              else 'normal-parse-error'" />
    </xsl:function>

    <xsl:function name="tests:parsedClass" as="xs:string" >
        <xsl:param name="result" as="element(result)" />

        <xsl:sequence select="if ($result/parsed eq 'true')
                              then 'parses'
                              else 'parse-error'" />
    </xsl:function>

    <xsl:function name="tests:reportHead" as="element(head)" >
        <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title>Results of the Consensus Test Suite</title>
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
                .status-green       { background-color: green;  }

                .table-container {
                                     max-height:  800px;      /* Set the height of the container */
                                     overflow-y: auto;        /* Enable vertical scrolling */
                                     border: 1px solid #ccc;  /* Optional border */
                                 }
                .passed { color: green; }
                .parses { color: green; }
                .parse-error { color: orange; }

                .consensusGreen  { background-color: green;  }
                .consensusOrange { background-color: orange; }
                .consensusYellow { background-color: yellow; }
                .consensusRed    { background-color: red;    }

                .col-0 { width:  3%; }
                .col-1 { width: 22%; }
                .col-2 { width:  3%; }
                .col-3 { width: 14%; }
                .col-4 { width: 14%; }
                .col-5 { width: 14%; }
                .col-6 { width: 14%; }
                .col-7 { width: 16%; }

                .summary  { border: 1px solid rgb(140 140 140);
                            table-layout: auto;
                          }

            '}</style>
        </head>
    </xsl:function>

    <xsl:function name="tests:tableHead" as="element(thead)" >
        <thead class="testshead">
            <tr class="centered">
                <th class="centered col-0 testshead">#</th>
                <th class="centered col-1 testshead">Test Name</th>
                <th class="centered col-2 testshead">Parses</th>
                <th class="centered col-3 testshead">Query</th>
                <th class="centered col-4 testshead">QueryArg</th>
                <th class="centered col-5 testshead">Output Values</th>
                <th class="centered col-6 testshead">Output Paths</th>
                <th class="centered col-7 testshead">Consensus</th>
            </tr>
        </thead>
    </xsl:function>

    <xsl:function name="tests:results" as="element(result)*">

        <xsl:for-each select="$selectorFiles" >

            <xsl:sort />

            <xsl:variable name="selectorUri" as="xs:anyURI" select="." />
            <xsl:variable name="testName"    as="xs:string" select="replace(string($selectorUri),
                                                                            '^.*[/]([^/]*)[/]selector$',
                                                                            '$1')" />
            <xsl:variable name="query"       as="xs:string" select="$selectorUri => unparsed-text()
                                                                                 => tests:removeTrailingNewline()" />
            <xsl:variable name="queryArg"    as="item()"    select="resolve-uri('document.json', $selectorUri)
                                                                               => json-doc()" />

            <xsl:variable name="getSegmentsMap" as="map(*)" >
                <xsl:map>
                    <xsl:try>
                        <xsl:map-entry key="'segments'" select="ajp:getSegments($query)" />
                        <xsl:catch>
                            <xsl:map-entry key="'error'"
                                           select="ajp:errorSummary($err:code, $err:description)" />
                        </xsl:catch>
                    </xsl:try>
                </xsl:map>
            </xsl:variable>

            <xsl:variable name="output" as="map(xs:string, item()?)*"
                          select="if (map:keys($getSegmentsMap) = 'segments')
                                  then ajp:applySegments($queryArg, $getSegmentsMap?segments)
                                  else ()
                                 " />

            <result>
                    <number>{       position()                                          }</number>
                    <name>{         $testName                                           }</name>
                    <parsed>{       map:keys($getSegmentsMap) = 'segments'              }</parsed>
                    <query>{        $query
                                          => ajp:replaceHigherPlaneChars()
                                          => ajp:escape()                               }</query>
                    <queryArg>{     tests:prettyPrintJson( $queryArg )
                                          => ajp:replaceHigherPlaneChars()
                                          => ajp:escape()                               }</queryArg>
                <xsl:if test="map:keys($getSegmentsMap) = 'segments'" >
                    <outputValues>{ tests:prettyPrintJson( ajp:arrayOfValues($output) )
                                          => ajp:replaceHigherPlaneChars()
                                          => ajp:escape()                               }</outputValues>
                    <outputPaths>{  tests:prettyPrintJson( ajp:arrayOfPaths ($output) ) }</outputPaths>
                </xsl:if>
                <xsl:if test="map:keys($getSegmentsMap) = 'error'" >
                    <parseError>{   $getSegmentsMap?error                               }</parseError>
                </xsl:if>
            </result>
        </xsl:for-each>

    </xsl:function>

    <xsl:function name="tests:consensusText" as="xs:string" >
        <xsl:param name="result" as="element(result)" />

        <xsl:variable name="consensus" as="element(consensus)"
                      select="$consensuses/query[@name eq $result/name]/consensus" />

        <xsl:sequence select="if ($consensus/none)
                              then 'No consensus'
                              else if ($consensus/p eq 'Not supported')
                              then $consensus/p
                              else if ($consensus/pre/code)
                              then ( parse-json($consensus/pre/code) => tests:prettyPrintJson() )
                              else 'error in consensus retrieval'
                             " />
    </xsl:function>

    <xsl:function name="tests:consensusClass" as="xs:string" >
        <xsl:param name="result" as="element(result)" />

        <xsl:variable name="consensus" as="element(consensus)"
                      select="$consensuses/query[@name eq $result/name]/consensus" />

        <xsl:sequence select="if ($consensus/none)
                              then 'consensusOrange'
                              else if ($result/parsed eq 'false'
                                        and
                                       $consensus/p eq 'Not supported')
                              then 'consensusGreen'
                              else if ($result/parsed eq 'false')
                              then 'consensusRed'
                              else if (tests:compareValues($result, $consensus))
                              then 'consensusGreen'
                              else if (tests:compareValuesAnyOrder($result, $consensus))
                              then 'consensusYellow'
                              else 'consensusRed'
                             " />
    </xsl:function>

    <xsl:function name="tests:compareValues" as="xs:boolean" >
        <xsl:param name="result"    as="element(result)"    />
        <xsl:param name="consensus" as="element(consensus)" />

        <xsl:sequence select="deep-equal($result/outputValues => parse-json(),
                                         $consensus/pre/code  => parse-json())" />
    </xsl:function>

    <xsl:function name="tests:compareValuesAnyOrder" as="xs:boolean" >
        <xsl:param name="result"    as="element(result)"    />
        <xsl:param name="consensus" as="element(consensus)" />

        <xsl:variable name="resultArray"    as="array(*)" select="$result/outputValues => parse-json()" />
        <xsl:variable name="consensusArray" as="array(*)" select="$consensus/pre/code  => parse-json()" />

        <xsl:sequence select="if (array:size($resultArray) ne array:size($consensusArray))
                              then false()
                              else tests:compareArraysAnyOrder($resultArray, $consensusArray)
                             " />
    </xsl:function>

    <xsl:function name="tests:compareArraysAnyOrder" as="xs:boolean" >
        <xsl:param name="a" as="array(*)" />
        <xsl:param name="b" as="array(*)" />

        <xsl:sequence select="if (array:size($a) eq 0)
                              then true()
                              else ( let $matchIndex := tests:indicesMatchingItem(array:head($a), $b)[1]
                                     return if (count($matchIndex) eq 0)
                                            then false()
                                            else tests:compareArraysAnyOrder(array:tail($a),
                                                                             array:remove($b, $matchIndex))
                                   )
                             " />
    </xsl:function>

    <xsl:function name="tests:indicesMatchingItem" as="xs:integer*" >
        <xsl:param name="item" as="item()?"  />
        <xsl:param name="b"    as="array(*)" />

        <xsl:sequence select="for $i in (1 to array:size($b))
                              return $i[ deep-equal($item, $b($i)) ]
                             " />
    </xsl:function>

    <xsl:function name="tests:removeTrailingNewline" >
        <xsl:param name="s" as="xs:string" />

        <xsl:sequence select="if (matches($s, '\n$'))
                              then substring($s, 1, string-length($s) - 1)
                              else $s
                             " />
    </xsl:function>

</xsl:stylesheet>
