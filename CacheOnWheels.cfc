<cfcomponent>
	<cffunction name="init" >
		<cfset this.version = "1.0" />
		
		<!--- Must use private $wheels directory since the main "wheels" struct isn't initialized yet --->
		<cfset application.cacheonwheels.storage = application.$wheels.cacheStorage />
		<cfset application.cacheonwheels.cacheSettings = {} />
		
		<cfset $initializeSettings() />
		<cfset $initializeCache() />
		
		<cfreturn this />
	</cffunction>
	
	<cffunction name="$initializeCache" access="public" returntype="void" >
		<cfargument name="storage" type="string" required="false" default="#application.cacheonwheels.storage#">
		<cfargument name="cacheSettings" type="struct" required="false" default="#application.cacheonwheels.cacheSettings#">
		<cfargument name="defaultCacheTime" type="numeric" required="false" default="#application.wheels.defaultCacheTime#">
		<cfargument name="cacheCullPercentage" type="numeric" required="false" default="#application.wheels.cacheCullPercentage#">
		<cfargument name="cacheCullInterval" type="numeric" required="false" default="#application.wheels.cacheCullInterval#">
		<cfargument name="maximumItemsToCache" type="numeric" required="false" default="#application.wheels.maximumItemsToCache#">
		<cfargument name="cacheDatePart" type="string" required="false" default="#application.wheels.cacheDatePart#">
		<cfargument name="showDebugInformation" type="boolean" required="false" default="#application.wheels.showDebugInformation#">
		<cfargument name="nameSpaces" type="string" required="false" default="actions,images,pages,partials,schemas">
		<cfargument name="defaultNameSpace" type="string" required="false" default="internal">
		
		<cfset var loc = {} />
		<cfset variables.$instance = {} />
		<cfset StructAppend(variables.$instance, arguments) />
		<cfset variables.$instance.cacheLastCulledAt = Now() />
		
		<cfif ARGUMENTS.storage eq "">
			<cfset ARGUMENTS.storage = "memory" />
		</cfif>

		<cfset variables.$instance.cache = CreateObject("component", "cache.storage.#ARGUMENTS.storage#").init(argumentCollection=arguments.cacheSettings) />
		<cfset application.cacheonwheels = variables.$instance />
	</cffunction>
	
	<cffunction name="$initializeSettings" access="public" returntype="void" >
		<cfset var loc = {} />
		
		<!--- Set defaults for each property necessary for the plugin so no errors occur out of the gate --->
		<cfparam name="application.cacheonwheels.storage" default="#application.cacheonwheels.storage#" />
		<cfparam name="application.cacheonwheels.cacheSettings" default="#StructNew()#" />
	</cffunction>

	<cffunction name="$addToCache" returntype="void" access="public" output="false">
		<cfargument name="key" type="string" required="true">
		<cfargument name="value" type="any" required="true">
		<cfargument name="time" type="numeric" required="false" default="#application.wheels.defaultCacheTime#">
		<cfargument name="category" type="string" required="false" default="main">
		
		
		<cfset application.cacheonwheels.cache.add(argumentCollection=arguments) />
	</cffunction>
	
	<cffunction name="$getFromCache" returntype="any" access="public" output="false" mixin="controller">
		<cfargument name="key" type="string" required="true">
		<cfargument name="category" type="string" required="false" default="main">
	
		<cfreturn application.cacheonwheels.cache.get(argumentCollection=arguments) />
	</cffunction>
	
	<cffunction name="$removeFromCache" returntype="void" access="public" output="false" mixin="controller">
		<cfargument name="key" type="string" required="true">
		<cfargument name="category" type="string" required="false" default="main">

		<cfset application.cacheonwheels.cache.delete(argumentCollection=arguments) />
	</cffunction>
	
	<cffunction name="$clearCache" returntype="void" access="public" output="false" mixin="controller">
		<cfargument name="category" type="string" required="false" default="">


		<cfset application.cacheonwheels.cache.clear(ARGUMENTS.category) />
	</cffunction>
	
	<cffunction name="$isAvailable" access="public" returntype="boolean" >
		<cfset application.cacehonwheels.cache.isAvailable(argumentCollection=arguments) />
	</cffunction>
	
	<cffunction name="getCacheStats" access="public" returntype="any" >
		<cfset application.cacheonwheels.cache.getStats() />
	</cffunction>
	
</cfcomponent>