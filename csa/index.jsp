<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ page isELIgnored="false" %> 

<%@include file="/html-lib/pages/partials/noCache.jsp" %>
<%@include file="/html-lib/pages/partials/user.jsp" %>
<%@include file="/html-lib/pages/partials/perspectiveResourceManager.jsp" %>
<!DOCTYPE html>
<html ng-app="dashboardApp" ng-strict-di>
    <head>
        <meta http-equiv="X-UA-Compatible" content="IE=Edge,chrome=1"/>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>

        <!-- Responsive features for bootstrap -->
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">

        <title><%= perspectiveResourceManager.getString("product_title") %></title>

        <link rel="icon" href="/csa/static/img/favicon.ico" type="image/x-icon"/>
        <link rel="shortcut icon" href="/csa/static/img/favicon.ico" type="image/x-icon"/>

        <jsp:include page="/html-lib/pages/partials/browserCheck.jsp"/>
        <jsp:include page="/html-lib/pages/partials/licenseCheck.jsp"/>
        <jsp:include page="/html-lib/pages/partials/csaObject.jsp"/>

        <!-- Core -->
        <link rel="stylesheet" type="text/css" media="all" href="css/base.css?v=1472197538501"/>

        <!-- Product perspective stylesheets -->
        <c:if test="${'developer'.equalsIgnoreCase(productPerspective)}">
            <link rel="stylesheet" type="text/css" media="all" href="/csa/html-lib/css/common/common.developer.css?v=1472197538501"/>
        </c:if>

        <link rel="stylesheet" type="text/css" media="all" href="/csa/custom/custom.css?v=1472197538501"/>

        <script type="text/javascript">
            CSA.htmlLibPath = "/csa/html-lib/"; //TODO Remove this when we migrate all builds, move to commonIdeRuntime
            var require = {
                baseUrl: "js/",
                urlArgs: "v=" + CSA.version
            };
        </script>

        <script data-main="dashboard/main" src="/csa/html-lib/js/3rdparty/require/require.js"></script>
    </head>
    <body hp-browser-identity>

        <c:if test="${'enterprise'.equalsIgnoreCase(productPerspective)}">
            <!-- Security Top Banner -->
            <jsp:include page="/html-lib/pages/partials/securityBanner.jsp"/>
        </c:if>

        <c:if test="${('enterprise'.equalsIgnoreCase(productPerspective) || 'codar'.equalsIgnoreCase(productPerspective))}">
            <!-- License Message Banner -->
            <%-- <jsp:include page="/html-lib/pages/partials/licenseBanner.jsp"/> --%>
        </c:if>

        <jsp:include page="/html-lib/pages/partials/ieCompatBanner.jsp"/>

        <!-- This page should remain very thin, all content will be injected into the page id -->
        <div id="maincontent" class="flex-row-xs" data-ui-view></div>
        <div hp-progress-indicator></div>

        <c:if test="${'enterprise'.equalsIgnoreCase(productPerspective)}">
            <!-- Security Bottom Banner -->
            <jsp:include page="/html-lib/pages/partials/securityBanner.jsp"/>
        </c:if>
    </body>
</html>
