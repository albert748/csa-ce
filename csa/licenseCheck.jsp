<%@page import="com.hp.csa.web.util.LicenseHelper" %>
<%@ page import="java.util.List" language="java" %>


<script type="text/javascript">
<%
	LicenseHelper helper = new LicenseHelper();
	
    boolean communityEdition = helper.isCommunityEdition();
    String requestFromCommunityModule = request.getParameter("communityActivation");
    if (requestFromCommunityModule != null)
    {
        boolean activated = helper.isCommunityEditionActivated();
        if (!communityEdition || activated) {
            %>window.location.href = "/csa/dashboard/index.jsp";<%
        }
    }
    else if (!communityEdition)
    {
        boolean activated = helper.isCommunityEditionActivated();
        if (!activated) {
            boolean registered = helper.isCommunityEditionRegistered();
            if (registered){
                %>window.location.href = "/csa/community-activation/index.jsp#/communityactivation/productactivation";<%
            }			
            else {
                %>window.location.href = "/csa/community-activation/index.jsp";<%
            }	
		}
    }
	
	String feature = request.getParameter("featureId");
	boolean featureEnabled = false;
	if(feature != null){
		 Integer featureId = Integer.parseInt(feature);
		 featureEnabled = helper.isLicenseFeatureEnabled(featureId);
		 if(!featureEnabled){
	    	response.sendRedirect("/csa/dashboard/index.jsp");
	    } 	
	}else{
		featureEnabled = true;
	}
    List<Integer> featureList = helper.getLicenseFeatureList();    
%>

var featureEnabled = <%= featureEnabled %>;
if(!featureEnabled){
		window.location.href = "/csa/dashboard/index.jsp";
	    } 
var License = { features: <%= featureList %>};
</script>
