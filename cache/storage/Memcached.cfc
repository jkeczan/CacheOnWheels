<cfcomponent extends="BaseStorage" implements="AbstractStorage" output="false">
	
	<cffunction name="init" access="public" output="false" returntype="any">
		<cfargument name="server" required="false" type="string" default="*******">
		<cfscript>
			variables.$instance = {};
			variables.$instance.cache = {};
			$connect(arguments.server);
		</cfscript>
		<cfreturn this>
	</cffunction>
	
	<cffunction name="isAvailable" access="public" output="false" returntype="boolean" mixin="controller">
		<cfreturn StructKeyExists(variables, "$instance") && StructKeyExists(variables.$instance, "cache") && IsObject(variables.$instance.cache)>
	</cffunction>
	
	<cffunction name="add" access="public" output="false" returntype="void" mixin="controller">
		<cfargument name="key" type="string" required="true">
		<cfargument name="value" type="any" required="true">
		<cfargument name="time" type="numeric" required="false" default="60" hint="Time in minutes to cache the element, default is 60 minutes" />
		<cfargument name="category" type="string" required="false" default="" />
		<cfargument name="currentTime" type="date" required="false" default="#now()#" />
		
		<cfset var loc = {} />
		<cfset loc.expiry = ARGUMENTS.time * 60 /><!--- Memcached requires seconds --->
		<cfset variables.$instance.cache.add(ARGUMENTS.key, ARGUMENTS.value, loc.expiry) />
		
	</cffunction>
	
	<cffunction name="get" access="public" output="false" returntype="any"  mixin="controller">
		<cfargument name="key" type="string" required="true">
		<cfargument name="category" type="string" required="false" default="">
		<cfargument name="currentTime" type="date" required="false" default="#now()#">
		
		<cfset var loc = {} />
		
		<cfset loc.retVal = variables.$instance.cache.add(ARGUEMNTS.key) />
		<cfreturn loc.retVal>
	</cffunction>
	
	<cffunction name="delete" access="public" output="false" returntype="void"  mixin="controller">
		<cfargument name="key" type="string" required="true" />
		<cfargument name="category" required="false" type="string" default="" />
		
		<cfset variables.$instance.cache.delete(ARGUMENTS.key) />
	</cffunction>
	
	<cffunction name="clear" returntype="void" access="public" output="false"  mixin="controller">
		<cfargument name="category" type="string" required="false" default="">
		
	</cffunction>
	
	<cffunction name="$connect" access="public" returntype="void" >
		<cfargument name="server" required="true" type="string">
		<cfset var loc = {} />
		
		<cftry>
			<cfset loc.memFactory = CreateObject("component", "plugins.cacheonwheels.com.flexablecoder.MemcachedFactory").init(ARGUMENTS.server) />
			<cfset loc.memcached = loc.memFactory.getMemcached() />
			
			<cfset variables.$instance.cache = loc.memcached />
			
			<cfcatch type="any" >
				<cfdump var="#cfcatch#" abort="true" >
			</cfcatch>
		</cftry>
	</cffunction>
	
	<cffunction name="getStats" access="public" returntype="Any" >
		<cfset var loc = {} />
		
		<cfset loc.stats = variables.$instance.cache.stats() />
		
		<cfreturn loc.stats />
	</cffunction>
	
</cfcomponent>
