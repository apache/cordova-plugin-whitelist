/*
       Licensed to the Apache Software Foundation (ASF) under one
       or more contributor license agreements.  See the NOTICE file
       distributed with this work for additional information
       regarding copyright ownership.  The ASF licenses this file
       to you under the Apache License, Version 2.0 (the
       "License"); you may not use this file except in compliance
       with the License.  You may obtain a copy of the License at

         http://www.apache.org/licenses/LICENSE-2.0

       Unless required by applicable law or agreed to in writing,
       software distributed under the License is distributed on an
       "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
       KIND, either express or implied.  See the License for the
       specific language governing permissions and limitations
       under the License.
*/

package org.apache.cordova.whitelist;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.ConfigXmlParser;
import org.apache.cordova.Whitelist;
import org.xmlpull.v1.XmlPullParser;

public class LegacyWhitelistPlugin extends CordovaPlugin {

    private Whitelist internalWhitelist = new Whitelist();
    private Whitelist externalWhitelist = new Whitelist();

    private static final String TAG = "Whitelist";

    @Override
    public void pluginInitialize() {
        // Add implicitly allowed URLs
        internalWhitelist.addWhiteListEntry("file:///*", false);
        internalWhitelist.addWhiteListEntry("content:///*", false);
        internalWhitelist.addWhiteListEntry("data:*", false);

        new ConfigXmlParser(){
            @Override
            public void handleStartTag(XmlPullParser xml) {
                String strNode = xml.getName();
                if (strNode.equals("access")) {
                    String origin = xml.getAttributeValue(null, "origin");
                    String subdomains = xml.getAttributeValue(null, "subdomains");
                    boolean external = (xml.getAttributeValue(null, "launch-external") != null);
                    if (origin != null) {
                        if (external) {
                            externalWhitelist.addWhiteListEntry(origin, (subdomains != null) && (subdomains.compareToIgnoreCase("true") == 0));
                        } else {
                            if ("*".equals(origin)) {
                                // Special-case * origin to mean http and https when used for internal
                                // whitelist. This prevents external urls like sms: and geo: from being
                                // handled internally.
                                internalWhitelist.addWhiteListEntry("http://*/*", false);
                                internalWhitelist.addWhiteListEntry("https://*/*", false);
                            } else {
                                internalWhitelist.addWhiteListEntry(origin, (subdomains != null) && (subdomains.compareToIgnoreCase("true") == 0));
                            }
                        }
                    }
                }
            }
            @Override
            public void handleEndTag(XmlPullParser xml) {
            }
        }.parse(webView.getContext());
    }

    public Boolean shouldAllowRequest(String url) {
        return internalWhitelist.isUrlWhiteListed(url);
    }

    public Boolean shouldAllowNavigation(String url) {
        return internalWhitelist.isUrlWhiteListed(url);
    }

    public Boolean shouldOpenExternalUrl(String url) {
        return externalWhitelist.isUrlWhiteListed(url);
    }

}
