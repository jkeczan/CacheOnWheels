<cfcomponent extends="BaseStorage" implements="AbstractStorage" output="false">
	
	<cffunction name="init" access="public" output="false" returntype="any">
		<cfset super.init() />
		<cfset variables.$instance.defaultCacheTime = 60 />
		<cfreturn this>
	</cffunction>
	
	<cffunction name="isAvailable" access="public" output="false" returntype="boolean">
		<cfreturn StructKeyExists(variables, "$instance") && StructKeyExists(variables.$instance, "cache")>
	</cffunction>
	
	<cffunction name="add" returntype="void" access="public" output="false">
		<cfargument name="key" type="string" required="true">
		<cfargument name="value" type="any" required="true">
		<cfargument name="time" type="numeric" required="false" default="#variables.$instance.defaultCacheTime#">
		<cfargument name="category" type="string" required="false" default="#variables.$instance.defaultNameSpace#">
		<cfargument name="currentTime" type="date" required="false" default="#now()#">
		
		<cfscript>
			var loc = {};
			if (application.wheels.cacheCullPercentage > 0 && application.wheels.cacheLastCulledAt < DateAdd("n", -application.wheels.cacheCullInterval, Now()) && $cacheCount() >= application.wheels.maximumItemsToCache)
			{
				// cache is full so flush out expired items from this cache to make more room if possible
				loc.deletedItems = 0;
				loc.cacheCount = $cacheCount();
				for (loc.key in application.wheels.cache[arguments.category])
				{
					if (Now() > application.wheels.cache[arguments.category][loc.key].expiresAt)
					{
						$removeFromCache(key=loc.key, category=arguments.category);
						if (application.wheels.cacheCullPercentage < 100)
						{
							loc.deletedItems++;
							loc.percentageDeleted = (loc.deletedItems / loc.cacheCount) * 100;
							if (loc.percentageDeleted >= application.wheels.cacheCullPercentage)
							{
								break;
							}
						}
					}
				}
				application.wheels.cacheLastCulledAt = Now();
			}
			if ($cacheCount() < application.wheels.maximumItemsToCache)
			{
				loc.cacheItem = {};
				loc.cacheItem.expiresAt = DateAdd(application.wheels.cacheDatePart, arguments.time, Now());
				if (IsSimpleValue(arguments.value))
				{
					loc.cacheItem.value = arguments.value;
				}
				else
				{
					loc.cacheItem.value = Duplicate(arguments.value);
				}
				application.wheels.cache[arguments.category][arguments.key] = loc.cacheItem;
			}
		</cfscript>
	</cffunction>
	
	<cffunction name="$cacheCount" returntype="numeric" access="public" output="false">
		<cfargument name="category" type="string" required="false" default="">
		<cfscript>
			var loc = {};
			if (Len(arguments.category))
			{
				loc.returnValue = StructCount(application.wheels.cache[arguments.category]);
			}
			else
			{
				loc.returnValue = 0;
				for (loc.key in application.wheels.cache)
				{
					loc.returnValue += StructCount(application.wheels.cache[loc.key]);
				}
			}
		</cfscript>
		<cfreturn loc.returnValue>
	</cffunction>
	
	<cffunction name="get" returntype="any" access="public" output="false">
		<cfargument name="key" type="string" required="true">
		<cfargument name="category" type="string" required="false" default="">
		<cfargument name="currentTime" type="date" required="false" default="">
		
		<!---Interfaces do not allow calculated defaults --->
		<cfparam name="ARGUMENTS.currentTime" default="#now()#" >
		<cfparam name="ARGUMENTS.category" default="#variables.$instance.defaultNameSpace#" >
		
		<cfscript>
			var loc = {};
			loc.returnValue = false;
			try
			{
				if (StructKeyExists(application.wheels.cache[arguments.category], arguments.key))
				{
					if (Now() > application.wheels.cache[arguments.category][arguments.key].expiresAt)
					{
						$removeFromCache(key=arguments.key, category=arguments.category);
					}
					else
					{
						if (IsSimpleValue(application.wheels.cache[arguments.category][arguments.key].value))
						{
							loc.returnValue = application.wheels.cache[arguments.category][arguments.key].value;
						}
						else
						{
							loc.returnValue = Duplicate(application.wheels.cache[arguments.category][arguments.key].value);
						}
					}
				}
			}
			catch (any e) {}
		</cfscript>
	</cffunction>
	
	<cffunction name="delete" returntype="void" access="public" output="false">
		<cfargument name="key" type="string" required="true">
		<cfargument name="category" type="string" required="false" default="">
		
		<!---Interfaces do not allow calculated defaults --->
		<cfparam name="ARGUMENTS.category" default="#variables.$instance.defaultNameSpace#" />
		
		<cfset variables.$instance.cache.delete(arguments.key)>
		<cfset StructDelete(variables.$instance.stats[arguments.category], arguments.key)>
	</cffunction>
	
	<cffunction name="count" returntype="numeric" access="public" output="false">
		<cfargument name="category" type="string" required="false" default="">
		<cfscript>
			var loc = {};
			if (Len(arguments.category))
			{
				loc.returnValue = StructCount(variables.$instance.stats[arguments.category]);
			}
			else
			{
				loc.returnValue = 0;
				for (loc.category in variables.$instance.stats)
					loc.returnValue = loc.returnValue + StructCount(variables.$instance.stats[loc.category]);
			}
			return loc.returnValue;
		</cfscript>
	</cffunction>
	
	<cffunction name="clear" returntype="void" access="public" output="false">
		<cfargument name="category" type="string" required="false" default="">
		
	</cffunction>
	
	<cffunction name="getStats" access="public" returntype="any" >
		<cfset var loc = {} />
		
		<cfset loc.stats = {} />
		<cfset loc.stats.nostats = "No Stats are available for this storage options" />
		<cfreturn loc.stats />
	</cffunction>
	
</cfcomponent>