<cfcomponent name="MemcachedFactory" hint="The Factory for Memcached, should be a scope singleton">
	
	<cfscript>
		instance = StructNew();
		instance['Memcached'] = "";
		instance['FactoryServers'] = "";
		instance['FactoryTimeout'] = 0;
		instance['FactoryUnit'] = "";
	</cfscript>
	
	<cffunction name="init" access="public" returntype="MemcachedFactory" output="false"
		hint="Our constructor.">
		<cfargument name="servers" type="string" required="false" hint="comma delimited list of servers" />
		<cfargument name="defaultTimeout" type="numeric" required="false" default="-1" 
				hint="the number of nano/micro/milli/seconds to wait for the response.  
				a timeout setting of 0 will wait forever for a response from the server
				*** this defaults to 400  ***
				"/>
		<cfargument name="defaultUnit" type="string" required="false" default=""
				hint="The timeout unit to use for the timeout this will 
					*** this defaults to milliseconds ***
				"/>
		<!--- <cfargument name="servers" type="array" required="false" /> --->
		<cfscript>
			// if (structKeyExists(arguments, "servers")) { }
			
			if (NOT structKeyExists(arguments, "servers") or listlen(arguments.servers) eq 0) {
				arguments.servers = "127.0.0.1:11211";
			}
			
			setMemcached(createObject("component", "Memcached").init(arguments.servers));
			if (arguments.defaultTimeout gt -1)	{
				instance.Memcached.setDefaultRequestTimeout = arguments.defaultTimeout;
			}
			if (len(trim(arguments.defaultUnit)))	{
				instance.Memcached.setDefaultTimeoutUnit = arguments.defaultUnit;
			}
			setServers(arguments.servers);
			setTimeout(arguments.defaultTimeout);
			setUnit(arguments.defaultUnit);
			return this;
		</cfscript>
	</cffunction>

	<cffunction name="getMemcached" access="public" returntype="any" output="false"
		hint="Returns the main library class, that is used in all processing" >
		<cfif not StructkeyExists(instance,"Memcached") or isSimpleValue(instance.Memcached)>
			<!------------ if we can't find the instance.Memcached object, then i guess we need to reinit---->
			<cfset this.init()>
		</cfif>
		<cfreturn instance.Memcached />
	</cffunction>
	
	<cffunction name="setMemcached" access="private" returntype="void" output="false">
		<cfargument name="Memcached" type="component" required="true" />
		<cfset instance.Memcached = arguments.Memcached />
	</cffunction>
	
	<cffunction name="getServers" access="public" returntype="string" output="false"
		hint="Returns the main library class, that is used in all processing" >
		<cfreturn instance.factoryServers />
	</cffunction>
	
	<cffunction name="setServers" access="private" returntype="void" output="false">
		<cfargument name="Servers" type="string" required="true" />
		<cfset instance.Servers = arguments.Servers />
	</cffunction>
	
	<cffunction name="getTimeout" access="public" returntype="numeric" output="false"
		hint="Returns the main library class, that is used in all processing" >
		<cfreturn instance.factoryTimeout />
	</cffunction>
	
	<cffunction name="setTimeout" access="private" returntype="void" output="false">
		<cfargument name="Timeout" type="numeric" required="true" />
		<cfset instance.Timeout = arguments.Timeout />
	</cffunction>
	
	<cffunction name="getUnit" access="public" returntype="string" output="false"
		hint="Returns the main library class, that is used in all processing" >
		<cfreturn instance.factoryUnit />
	</cffunction>
	
	<cffunction name="setUnit" access="private" returntype="void" output="false">
		<cfargument name="Unit" type="string" required="true" />
		<cfset instance.Unit = arguments.Unit />
	</cffunction>
	
</cfcomponent>