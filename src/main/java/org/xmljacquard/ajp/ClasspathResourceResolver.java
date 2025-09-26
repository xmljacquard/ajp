package org.xmljacquard.ajp;

import net.sf.saxon.lib.ResourceRequest;
import net.sf.saxon.lib.ResourceResolver;

import javax.xml.transform.Source;
import javax.xml.transform.stream.StreamSource;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;

public class ClasspathResourceResolver implements ResourceResolver  {

    @Override
    public Source resolve(final ResourceRequest request) {
        URL         resourceURL = null;
        InputStream inputStream = null;

        if (null != request.uri) {
            try {
                resourceURL = new URL(request.uri);
                inputStream = resourceURL.openStream();
            } catch (final IOException e) {
                resourceURL = null;
            }
        }

        if (null == inputStream) {
            resourceURL = getClass().getClassLoader().getResource(request.relativeUri);
            if (null == resourceURL) {
                return null;
            }

            try {
                inputStream = resourceURL.openStream();
            } catch (final IOException e) {
                resourceURL = null;
            }
        }

        if (null == resourceURL) {
            // didn't find on classpath; saxon will now try its own method
            return null;
        }

        return streamSource(inputStream, resourceURL);
    }

    private StreamSource streamSource(final InputStream inputStream, final URL resourceURL) {
        final StreamSource source = new StreamSource();
        source.setSystemId(resourceURL.toString());
        source.setInputStream(inputStream);

        return source;
    }
}
