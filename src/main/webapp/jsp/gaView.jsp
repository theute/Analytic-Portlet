<%--
    Document   : gaView.jsp
    Created on : Apr 5, 2010, 12:58:00 AM
    Authors    : Benothman, Mikiela
--%>
<%@ page session="true" %>
<%@ page import="javax.portlet.PortletPreferences"%>
<%@ page import="java.util.Locale"%>
<%@ page import="java.util.List"%>
<%@ page import="java.util.Map"%>
<%@ page import="java.util.HashMap"%>
<%@ page import="java.util.Collection"%>
<%@ page import="java.util.ArrayList"%>
<%@ page import="org.exoplatform.services.organization.OrganizationService"%>
<%@ page import="org.exoplatform.services.organization.Group"%>
<%@ page import="org.exoplatform.services.organization.UserProfile"%>
<%@ page import="org.exoplatform.services.resources.LocaleConfigService"%>
<%@ page import="org.exoplatform.services.organization.Membership"%>
<%@ page import="org.exoplatform.container.ExoContainer"%>
<%@ page import="org.exoplatform.container.ExoContainerContext"%>
<%@ taglib uri="http://java.sun.com/portlet_2_0" prefix="portlet" %>

<portlet:defineObjects/>
<%
            // reset the default values for messages
            portletSession.setAttribute("error", "");
            portletSession.setAttribute("message", "");

            PortletPreferences prefs = renderRequest.getPreferences();
            String trackId = prefs.getValue("trackId", "");

            /* retrieve groups from preferences, to track user groups we compute
             * the intersection between user groups and the list of groups that
             * the administrator hope track
             */
            String groups[] = prefs.getValues("groups", new String[]{});

            ExoContainer container = ExoContainerContext.getContainerByName("portal");
            OrganizationService orgService = (OrganizationService) container.getComponentInstanceOfType(OrganizationService.class);

            // Since we took only root groups as tracking keys for groups and children
            // groups as tracking values, we use a map having root groups names as keys
            // and a list of children groups names as values
            Map<String, List<String>> tracking = new HashMap<String, List<String>>();
            for (String g : groups) {
                tracking.put(g, new ArrayList<String>());
            }

            java.security.Principal credentials = renderRequest.getUserPrincipal();

            if (credentials != null) {
                // a non-null credentials means that the user is authenticated
                Collection<Membership> memberShips = orgService.getMembershipHandler().
                        findMembershipsByUser(credentials.toString());
                // compute the intersection between the user groups and root ones
                for (Membership o : memberShips) {
                    for (String s : groups) {
                        if (o.getGroupId().startsWith("/" + s)) {
                            tracking.get(s).add(o.getGroupId());
                        }
                    }
                }
            }

            // retrieving language tracking parameter
            String lang = prefs.getValue("trackLang", "");
            boolean trackLang = false;
            if (!("".equals(lang))) {
                trackLang = Boolean.valueOf(lang);
            }

            // retrieving authentication tracking parameter
            String auth = prefs.getValue("trackAuth", "");
            boolean trackAuth = false;
            if (!("".equals(auth))) {
                trackAuth = Boolean.valueOf(auth);
            }

%>

<div>
    <script type="text/javascript">
        var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
        document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
    </script>
    <script type="text/javascript">
        try{
            var pageTracker = _gat._getTracker("<%=trackId%>");
       
        <%
                    for (String key : tracking.keySet()) {
                        Group group = orgService.getGroupHandler().findGroupById(key);
                        int i = 3;
                        for (String name : tracking.get(key)) {
        %>
                pageTracker._setCustomVar(<%=(i++)%>,"<%=group.getLabel()%>","<%=name%>",2);
        <%
                            if (i > 5) {
                                break;
                            }
                        }
                    }

                    if (trackLang) {
                        String portalLanguage = null;
                        if (credentials != null) {
                            // Extraction of the portal language
                            UserProfile userProfile = orgService.getUserProfileHandler().
                                    findUserProfileByName(credentials.getName());

                            if (userProfile != null) {
                                portalLanguage = userProfile.getUserInfoMap().get("user.language");
                            }
                        }

                        if (portalLanguage == null) {
                            // If the user is a guest so the browser language is taken
                            portalLanguage = renderRequest.getLocale().getLanguage();
                        }

        %>
                pageTracker._setCustomVar(1,"Language","<%=portalLanguage%>",3);
        <%
                    }

                    if (trackAuth) {
                        if (credentials != null) {
                            Collection<Membership> memberShips = orgService.getMembershipHandler().
                                    findMembershipsByUserAndGroup(credentials.getName(), "/platform/administrators");

                            if (!memberShips.isEmpty()) {
        %>
                pageTracker._setCustomVar(2,"Authenticated","<%="administrator"%>",2);
        <%

                                    } else {
        %>
                pageTracker._setCustomVar(2,"Authenticated","<%="user"%>",2);
        <%
                                    }

                                } else {
        %>
                pageTracker._setCustomVar(2,"Authenticated","<%="anonymous"%>",2);
        <%
                        }

                    }
        %>
                pageTracker._trackPageview();
            } catch(err) {}

    </script>

</div>
