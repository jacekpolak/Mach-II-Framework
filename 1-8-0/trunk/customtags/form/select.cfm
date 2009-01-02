<cfsetting enablecfoutputonly="true" />
<!---
License:
Copyright 2008 GreatBizTools, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Copyright: GreatBizTools, LLC
Author: Peter J. Farrell (peter@mach-ii.com)
$Id$

Created version: 1.8.0
Updated version: 1.8.0

Notes:
- REQUIRED ATTRIBUTES
	name		= AUTOMATIC|[string]
	type		= select
- OPTIONAL ATTRIBUTES
	disabled	= disabled|[null]
	size		= [numeric]
	checkValue	= [string]|[null]
- STANDARD FORM ATTRIBUTES
- EVENT ATTRIBUTES
--->
<cfimport prefix="form" taglib="/MachII/customtags/form/" />

<cfif thisTag.ExecutionMode IS "start">

	<!--- Setup the tag --->
	<cfinclude template="/MachII/customtags/form/helper/helper.cfm" />		
	<cfset setupTag("select", false) />
	
	<!--- Ensure certain attributes are defined --->
	<cfset ensurePathOrName() />
		
	<!--- Resolve path if defined--->
	<cfif StructKeyExists(attributes, "path")>
		<cfparam name="attributes.name" type="string" default="#getNameFromPath(attributes.path)#" />
		<cfset attributes.checkValue = resolvePath(attributes.path) />
	</cfif>
	
	<!--- Set defaults --->
	<cfparam name="attributes.checkValue" type="string" default="" />
	<cfset request._MachIIFormLib.selectCheckValue = attributes.checkValue />
				
	<!--- Add options if items are available --->
	<cfif StructKeyExists(attributes, "items")>
		<cfsavecontent variable="variables.options">
			<form:option items="#attributes.items#"/>
		</cfsavecontent>
	</cfif>
	
	<!--- Set required attributes--->
	<cfset setAttribute("name") />

	<!--- Set optional attributes --->
	<cfset setAttributeIfDefined("size") />
	<cfset setAttributeIfDefined("multiple", "multiple") />
	<cfset setAttributeIfDefined("disabled", "disabled") />
	
	<!--- Set standard and event attributes --->
	<cfset setStandardAttributes() />
	<cfset setEventAttributes() />
	
	<cfoutput>#doStartTag()#</cfoutput>
<cfelse>
	<cfif StructKeyExists(attributes, "options")>
		<cfset thisTag.GeneratedContent = attributes.options />
	</cfif>
	<cfoutput>#doEndTag()#</cfoutput>
</cfif>
<cfsetting enablecfoutputonly="false" />