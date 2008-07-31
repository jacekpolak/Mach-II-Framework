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
$Id: Log.cfc 584 2007-12-15 08:44:43Z peterfarrell $

Created version: 1.6.0
Updated version: 1.6.0

Notes:

Configuring for Mach-II logging only:
<property name="Logging" type="MachII.logging.LoggingProperty" />

This will turn on the MachIILog logger and display the log message 
in the request output.

Configuring multiple logging adapters:
<property name="Logging" type="MachII.logging.LoggingProperty">
	<parameters>
		<!-- Optionally turns logging on/off (loggingEnabled values in the adapters are still adhered to)-->
		<parameter name="loggingEnabled" value="false"/>
		<parameter name="CFLog">
			<struct>
				<key name="type" value="MachII.logging.loggers.CFLog.Logger" />
				<key name="loggingEnabled" value="false" />
				<key name="loggingLevel" value="warn" />
			</struct>
		</parameter>
		<parameter name="MachIILog">
			<struct>
				<key name="type" value="MachII.logging.loggers.MachIILog.Logger" />
				<key name="loggingEnabled" value="true" />
				<key name="loggingLevel" value="debug" />
			</struct>
		</parameter>
	</parameters>
</property>

See individual loggers for more information on configuration.

The LoggingProperty also will bind nested parameter values using ${} syntax. Mach-II only
will bind to root parameter values.
--->
<cfcomponent
	displayname="LoggingProperty"
	extends="MachII.framework.Property"
	output="false"
	hint="Allows you to configure the Mach-II logging features.">
	
	<!---
	PROPERTIES
	--->
	<cfset variables.defaultLoggerName = "MachII" />
	<cfset variables.defaultLoggerType = "MachII.logging.loggers.MachIILog.Logger" />
	<cfset variables.loggers = StructNew() />
	<cfset variables.loggingEnabled = true />
	
	<!---
	INITALIZATION / CONFIGURATION
	--->
	<cffunction name="configure" access="public" returntype="void" output="false"
		hint="Configures the property.">
		
		<cfset var params = getParameters() />
		<cfset var defaultLoggerParameters = StructNew() />
		<cfset var loggers = StructNew() />
		<cfset var key = "" />
		
		<!--- Load loggers --->
		<cfloop collection="#params#" item="key">
			<cfif IsStruct(params[key])>
				<cfset configureLogger(key, getParameter(key)) />
			</cfif>
		</cfloop>
		
		<!--- Configure the default logger since no loggers are registered --->
		<cfif NOT StructCount(getLoggers())>
			<cfset defaultLoggerParameters.type = variables.defaultLoggerType />
			<cfset configureLogger(variables.defaultLoggerName, defaultLoggerParameters) />
		</cfif>
		
		<!--- Configure the loggers --->
		<cfset loggers = getLoggers() />
		
		<cfloop collection="#loggers#" item="key">
			<cfset loggers[key].configure() />
		</cfloop>
		
		<!--- Set logging enabled/disabled --->
		<cfif NOT getParameter("loggingEnabled", true)>
			<cfset getAppManager().getLogFactory().disableLogging() />
		</cfif>
	</cffunction>
	
	<!---
	PUBLIC FUNCTIONS
	--->
	<cffunction name="disableLogging" access="public" returntype="void" output="false"
		hint="Disables logging.">
		<cfset getAppManager().getLogFactory().disableLogging() />
	</cffunction>
	
	<cffunction name="enableLogging" access="public" returntype="void" output="false"
		hint="Enables logging.">
		<cfset getAppManager().getLogFactory().enableLogging() />
	</cffunction>
	
	<!---
	PROTECTED FUNCTIONS
	--->
	<cffunction name="configureLogger" access="private" returntype="void" output="false"
		hint="Configures an logger.">
		<cfargument name="loggerName" type="string" required="true"
			hint="Name of the logger." />
		<cfargument name="parameters" type="struct" required="true"
			hint="Parameters for this logger.">
		
		<cfset var type = "" />
		<cfset var logger = "" />
		<cfset var loggerId = createLoggerId(arguments.loggerName) />
		<cfset var key = "" />
		
		<!--- Check and make sure the type is available otherwise there is not an adapter to create --->
		<cfif NOT StructKeyExists(arguments.parameters, "type")>
			<cfthrow type="MachII.properties.LoggingProperty"
				message="You must specify a 'type' for log adapter named '#arguments.loggerName#'." />
		</cfif>
		
		<!--- Bind values in parameters struct since Mach-II only binds parameters at the root level --->
		<cfloop collection="#arguments.parameters#" item="key">
			<cfset arguments.parameters[key] = bindValue(key, arguments.parameters[key]) />
		</cfloop>
		
		<!--- Create, init and configure the logger --->
		<cftry>
			<cfset logger = CreateObject("component", arguments.parameters.type).init(loggerId, getAppManager().getLogFactory(), arguments.parameters) />

			<cfcatch type="any">
				<cfif StructKeyExists(cfcatch, "missingFileName")>
					<cfthrow type="MachII.logging.CannotFindLogger"
						message="The LoggingProperty in module named '#getAppManager().getModuleName()#' cannot find a logger located at '#arguments.parameters.type#'."
						detail="Please check that this logger exists and that there is not a misconfiguration in the XML configuration file." />
				<cfelse>
					<cfrethrow />
				</cfif>
			</cfcatch>
		</cftry>
		
		<!--- Add a callback to the RequestManager if there is onRequestEnd method --->
		<cfif logger.isOnRequestEndAvailable()>
			<cfset getAppManager().getRequestManager().addOnRequestEndCallback(logger, "onRequestEnd") />
		</cfif>
		
		<!--- Add a callbacks to the RequestManager if there is pre/postRedirect methods --->
		<cfif logger.isPrePostRedirectAvailable()>
			<cfset getAppManager().getRequestManager().addPreRedirectCallback(logger, "preRedirect") />
			<cfset getAppManager().getRequestManager().addPostRedirectCallback(logger, "postRedirect") />
		</cfif>
		
		<!--- Add the logger --->
		<cfset addLogger(arguments.loggerName, logger) />
	</cffunction>
	
	<cffunction name="createLoggerId" access="private" returntype="string" output="false"
		hint="Creates a logger id.">
		<cfargument name="loggerName" type="string" required="true" />
		
		<cfset var moduleName = getAppManager().getModuleName() />
		
		<cfif NOT Len(moduleName)>
			<cfset moduleName = "_base_" />
		</cfif>
		
		<cfreturn Hash(arguments.loggerName & moduleName & GetTickCount() & RandRange(0, 10000)& RandRange(0, 10000)) />
	</cffunction>
	
	<!---
	ACCESSORS
	--->	
	<cffunction name="addLogger" access="private" returntype="void" output="false"
		hint="Adds a logger to the struct of registered loggers.">
		<cfargument name="loggerName" type="string" required="true" />
		<cfargument name="logger" type="MachII.logging.loggers.AbstractLogger" required="true" />
		
		<cfif StructKeyExists(variables.loggers, arguments.loggerName)>
			<cfthrow type="MachII.properties.LoggingProperty"
				message="A logger named '#arguments.loggerName#' already exists in module '#getAppManager().getModuleName()#'. Logger names must be unique." />
		<cfelse>
			<cfset variables.loggers[arguments.loggerName] = arguments.logger />
		</cfif>
	</cffunction>
	<cffunction name="getLoggers" access="public" returntype="struct" output="false"
		hint="Gets all the registered loggers.">
		<cfreturn variables.loggers />
	</cffunction>
	
</cfcomponent>